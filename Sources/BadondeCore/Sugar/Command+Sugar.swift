import Foundation
import SwiftCLI
import Configuration
import GitHub

private extension URL {
	static let jiraApiTokenUrl = URL(string: "https://id.atlassian.com/manage/api-tokens")!
}

#if !DEBUG
private enum CommandConstant {
	static let urlOpeningDelay: TimeInterval = 1.5
}
#endif

extension Command {
	func openURL(_ url: URL) throws {
		_ = try capture(bash: "open \"\(url)\"")
	}

	func openURL(_ url: URL, delay: TimeInterval) {
		let queue = DispatchQueue(label: "badonde_delay_queue")
		queue.asyncAfter(deadline: .now() + delay) {
			_ = try? self.openURL(url)
		}
	}
}

extension Command {
	func getOrPromptRawValue(forKeyPath keyPath: KeyPath, in configuration: KeyValueInteractive) throws -> String {
		if let value = try configuration.getRawValue(forKeyPath: keyPath) {
			return value
		}

		Logger.info("Credentials required", succeedPrevious: false)

		switch keyPath {
		case .jiraEmail:
			let jiraEmailInput = Input.readLine(
				prompt: "Enter JIRA email address:",
				secure: false,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "'\(input)' is invalid; \(invalidInputReason)"
				}
			)
			try configuration.setRawValue(jiraEmailInput, forKeyPath: keyPath)
			return jiraEmailInput
		case .jiraApiToken:
			#if !DEBUG
			openURL(.jiraApiTokenUrl, delay: CommandConstant.urlOpeningDelay)
			#endif
			let jiraApiTokenInput = Input.readLine(
				prompt: "Enter JIRA API token (generated at '\(URL.jiraApiTokenUrl)'):",
				secure: true,
				errorResponse: { _, invalidInputReason in
					self.stderr <<< "Invalid token; \(invalidInputReason)"
				}
			)
			try configuration.setRawValue(jiraApiTokenInput, forKeyPath: keyPath)
			return jiraApiTokenInput
		case .githubAccessToken:
			let usernameInput = Input.readLine(
				prompt: "Enter GitHub username:",
				secure: false,
				errorResponse: { _, invalidInputReason in
					self.stderr <<< "Invalid username; \(invalidInputReason)"
				}
			)
			let passwordInput = Input.readLine(
				prompt: "Enter GitHub password (never stored):",
				secure: true,
				errorResponse: { _, invalidInputReason in
					self.stderr <<< "Invalid password; \(invalidInputReason)"
				}
			)
			let authorizationTokenName = "Badonde for " + [NSUserName(), Host.current().localizedName].compacted().joined(separator: "@")
			let authorizationAPI = Authorization.API(username: usernameInput, password: passwordInput)
			let authorization = try authorizationAPI.createAuthorization(
				scopes: [.repo],
				note: authorizationTokenName,
				oneTimePassword: Input.readLine(
					prompt: "Enter GitHub two-factor authentication code:",
					secure: false,
					errorResponse: { _, invalidInputReason in
						self.stderr <<< "Invalid two-factor authentication code; \(invalidInputReason)"
					}
				)
			)
			try configuration.setRawValue(authorization.token, forKeyPath: keyPath)
			return authorization.token
		default:
			fatalError("KeyPath not supported for prompting")
		}
	}
}
