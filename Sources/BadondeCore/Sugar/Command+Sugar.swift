import Foundation
import SwiftCLI

private enum CommandConstant {
	#if !DEBUG
	static let urlOpeningDelay: TimeInterval = 1.5
	#endif
}

extension Command {
	func openURL(_ url: URL) throws {
		try run(bash: "open \"\(url)\"")
	}

	func openURL(_ url: URL, delay: TimeInterval) {
		let queue = DispatchQueue(label: "badonde_delay_queue")
		queue.asyncAfter(deadline: .now() + delay) {
			_ = try? self.openURL(url)
		}
	}
}

extension Command {
	func getOrPromptConfiguration(for store: ConfigurationStore) throws -> Configuration {
		let configuration: Configuration

		if let config = store.configuration {
			configuration = config
		} else {
			Logger.info("Configuration not found, credentials required")
			let jiraEmailInput = Input.readLine(
				prompt: "Enter JIRA email address:",
				secure: false,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "'\(input)' is invalid; \(invalidInputReason)"
				}
			)
			#if !DEBUG
			openURL(.jiraApiTokenUrl, delay: CommandConstant.urlOpeningDelay)
			#endif
			let jiraApiTokenInput = Input.readLine(
				prompt: "Enter JIRA API token (generated at '\(URL.jiraApiTokenUrl)':",
				secure: true,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "Invalid token; \(invalidInputReason)"
				}
			)
			#if !DEBUG
			openURL(.githubApiTokenUrl, delay: CommandConstant.urlOpeningDelay)
			#endif
			let githubAccessTokenInput = Input.readLine(
				prompt: "Enter GitHub API token (generated at '\(URL.githubApiTokenUrl)':",
				secure: true,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "Invalid token; \(invalidInputReason)"
				}
			)
			configuration = Configuration(
				jiraEmail: jiraEmailInput,
				jiraApiToken: jiraApiTokenInput,
				githubAccessToken: githubAccessTokenInput
			)
			try store.setConfiguration(configuration)
		}

		return configuration
	}
}
