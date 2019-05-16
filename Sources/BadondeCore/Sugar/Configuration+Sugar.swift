import Foundation
import Configuration

extension Configuration {
	enum Scope {
		case local(URL)
		case global

		var url: URL {
			switch self {
			case .local(let url):
				return url.appendingPathComponent(".badonde/config.json")
			case .global:
				return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/badonde/config.json")
			}
		}
	}

	static let supportedKeyPaths: [KeyPath] = [
		.jiraEmail,
		.jiraApiToken,
		.githubAccessToken,
		.gitRemote,
		.firebaseProjectId,
		.firebaseSecretToken,
	]

	convenience init(scope: Scope) throws {
		try self.init(contentsOf: scope.url, supportedKeyPaths: Configuration.supportedKeyPaths)
	}
}

extension DynamicConfiguration {
	convenience init(prioritizedScopes: [Configuration.Scope]) throws {
		try self.init(prioritizedConfigurations: prioritizedScopes.map(Configuration.init(scope:)))
	}
}

extension KeyPath {
	public static let jiraEmail = KeyPath(
		rawValue: "jira.email",
		description: "The email to use when connecting to JIRA"
	)!
	public static let jiraApiToken = KeyPath(
		rawValue: "jira.apiToken",
		description: "The API access token to use when connecting to JIRA"
	)!
	public static let githubAccessToken = KeyPath(
		rawValue: "github.accessToken",
		description: "The API access token to use when connecting to GitHub"
	)!
	public static let gitRemote = KeyPath(
		rawValue: "git.remote",
		description: "The Git remote to derive information off"
	)!
	public static let firebaseProjectId = KeyPath(
		rawValue: "firebase.projectId",
		description: "The Firebase Realtime DB's project id for analytics reporting"
	)!
	public static let firebaseSecretToken = KeyPath(
		rawValue: "firebase.secretToken",
		description: "The Firebase Realtime DB's secret token for analytics reporting"
	)!
}
