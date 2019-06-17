import Foundation
import SwiftCLI
import Configuration
import GitHub

private func open(_ url: URL, delay: TimeInterval) {
	let queue = DispatchQueue(label: "badonde_delay_queue")
	queue.asyncAfter(deadline: .now() + delay) {
		_ = try? open(url)
	}
}

private extension URL {
	static let jiraApiTokenUrl = URL(string: "https://id.atlassian.com/manage/api-tokens")!
	#if !DEBUG
	static let jiraApiTokenUrlOpeningDelay: TimeInterval = 1.5
	#endif
}

enum Prompter {
	enum Subject {
		case githubAccessToken
		case jiraEmail
		case jiraApiToken
	}

	static func prompt(_ subject: Subject) throws -> String {
		switch subject {
		case .githubAccessToken:
			let usernameInput = Input.readLine(prompt: "Enter GitHub username:")
			let passwordInput = Input.readLine(prompt: "Enter GitHub password (never stored):", secure: true)

			let authorizationTokenName = "Badonde for " + [NSUserName(), Host.current().localizedName].compacted().joined(separator: "@")
			let authorizationAPI = Authorization.API(username: usernameInput, password: passwordInput)
			let authorization = try authorizationAPI.createAuthorization(
				scopes: [.repo],
				note: authorizationTokenName,
				oneTimePassword: Input.readLine(prompt: "Enter GitHub two-factor authentication code:")
			)

			return authorization.token
		case .jiraEmail:
			return Input.readLine(prompt: "Enter JIRA email address:")
		case .jiraApiToken:
			#if !DEBUG
			open(.jiraApiTokenUrl, delay: URL.jiraApiTokenUrlOpeningDelay)
			#endif
			return Input.readLine(
				prompt: "Enter JIRA API token (generated at '\(URL.jiraApiTokenUrl)'):",
				secure: true
			)
		}
	}
}
