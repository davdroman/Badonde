import Foundation
import Configuration

extension Configuration {
	enum Scope {
		case local
		case global

		var url: URL {
			switch self {
			case .local:
				return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".badonde/config.json")
			case .global:
				return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/badonde/config.json")
			}
		}
	}

	convenience init(scope: Scope) throws {
		try self.init(
			contentsOf: scope.url,
			supportedKeyPaths: [
				.jiraEmail,
				.jiraAccessToken,
				.githubAccessToken,
				.gitRemote,
				.firebaseProjectId,
				.firebaseSecretToken,
			]
		)
	}
}

extension Configuration.KeyPath {
	public static let jiraEmail = Configuration.KeyPath(
		rawValue: "jira.email",
		description: "The email to use when connecting to JIRA"
	)!
	public static let jiraAccessToken = Configuration.KeyPath(
		rawValue: "jira.accessToken",
		description: "The API access token to use when connecting to JIRA"
	)!
	public static let githubAccessToken = Configuration.KeyPath(
		rawValue: "github.accessToken",
		description: "The API access token to use when connecting to GitHub"
	)!
	public static let gitRemote = Configuration.KeyPath(
		rawValue: "git.remote",
		description: "The Git remote to derive information off"
	)!
	public static let firebaseProjectId = Configuration.KeyPath(
		rawValue: "firebase.projectId",
		description: "The Firebase Realtime DB's project id for analytics reporting"
	)!
	public static let firebaseSecretToken = Configuration.KeyPath(
		rawValue: "firebase.secretToken",
		description: "The Firebase Realtime DB's secret token for analytics reporting"
	)!
}
