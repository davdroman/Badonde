import Foundation
import Configuration

extension Configuration {
	public enum Scope {
		case local(path: String)
		case global

		public var fullPath: String {
			switch self {
			case .local(let path):
				return URL(fileURLWithPath: path).appendingPathComponent(".badonde/config.json").path
			case .global:
				return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/badonde/config.json").path
			}
		}
	}

	public static let supportedKeyPaths: [KeyPath] = [
		.jiraEmail,
		.jiraApiToken,
		.githubAccessToken,
		.gitAutopush,
		.gitRemote,
		.firebaseProjectId,
		.firebaseSecretToken,
	]

	public convenience init(scope: Scope) throws {
		try self.init(contentsOfFile: scope.fullPath, supportedKeyPaths: Configuration.supportedKeyPaths)
	}
}

extension DynamicConfiguration {
	public convenience init(prioritizedScopes: [Configuration.Scope]) throws {
		try self.init(prioritizedConfigurations: prioritizedScopes.map(Configuration.init(scope:)))
	}
}

extension KeyPath {
	public static let jiraEmail = KeyPath(
		rawValue: "jira.email",
		description: "Email to use when connecting to JIRA"
	)!
	public static let jiraApiToken = KeyPath(
		rawValue: "jira.apiToken",
		description: "API access token to use when connecting to JIRA"
	)!
	public static let githubAccessToken = KeyPath(
		rawValue: "github.accessToken",
		description: "API access token to use when connecting to GitHub"
	)!
	public static let gitAutopush = KeyPath(
		rawValue: "git.autopush",
		description: "Push changes automatically if branch is ahead of remote (true/false)"
	)!
	public static let gitRemote = KeyPath(
		rawValue: "git.remote",
		description: "Git remote to derive information off"
	)!
	public static let firebaseProjectId = KeyPath(
		rawValue: "firebase.projectId",
		description: "Firebase Realtime DB's project id for analytics reporting"
	)!
	public static let firebaseSecretToken = KeyPath(
		rawValue: "firebase.secretToken",
		description: "Firebase Realtime DB's secret token for analytics reporting"
	)!
}
