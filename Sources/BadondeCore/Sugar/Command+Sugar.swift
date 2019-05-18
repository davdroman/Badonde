import Foundation
import SwiftCLI
import Configuration

private enum CommandConstant {
	#if !DEBUG
	static let urlOpeningDelay: TimeInterval = 1.5
	#endif
}

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

		Logger.info("Credentials required")

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
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "Invalid token; \(invalidInputReason)"
				}
			)
			try configuration.setRawValue(jiraApiTokenInput, forKeyPath: keyPath)
			return jiraApiTokenInput
		case .githubAccessToken:
			#if !DEBUG
			openURL(.githubApiTokenUrl, delay: CommandConstant.urlOpeningDelay)
			#endif
			let githubAccessTokenInput = Input.readLine(
				prompt: "Enter GitHub API token with 'repo' scope (generated at '\(URL.githubApiTokenUrl)'):",
				secure: true,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "Invalid token; \(invalidInputReason)"
				}
			)
			try configuration.setRawValue(githubAccessTokenInput, forKeyPath: keyPath)
			return githubAccessTokenInput
		default:
			fatalError("KeyPath not supported for prompting")
		}
	}
}
