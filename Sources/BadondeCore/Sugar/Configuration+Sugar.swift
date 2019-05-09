import Foundation
import Configuration

extension Configuration {
	static let supportedKeyPaths: [KeyPath] = [
		.jiraEmail,
		.jiraAccessToken,
		.githubAccessToken,
		.gitRemote,
		.firebaseProjectId,
		.firebaseSecretToken,
	]

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
		try self.init(contentsOf: scope.url, supportedKeyPaths: Configuration.supportedKeyPaths)
	}
}

final class DynamicConfiguration: KeyValueInteractive {
	private let configurations: [KeyValueInteractive]

	init(prioritizedScopes: [Configuration.Scope]) throws {
		self.configurations = try prioritizedScopes.map { try Configuration(scope: $0) }
	}

	func getValue<T>(ofType type: T.Type, forKeyPath keyPath: KeyPath) throws -> T? {
		return try configurations
			.lazy
			.reversed()
			.compactMap { try $0.getValue(ofType: type, forKeyPath: keyPath) }
			.first
	}

	func setValue<T>(_ value: T, forKeyPath keyPath: KeyPath) throws {
		try configurations.first?.setValue(value, forKeyPath: keyPath)
	}

	func getRawValue(forKeyPath keyPath: KeyPath) throws -> String? {
		return try configurations
			.lazy
			.reversed()
			.compactMap { try $0.getRawValue(forKeyPath: keyPath) }
			.first
	}

	func setRawValue(_ value: String, forKeyPath keyPath: KeyPath) throws {
		try configurations.first?.setRawValue(value, forKeyPath: keyPath)
	}

	func removeValue(forKeyPath keyPath: KeyPath) throws {
		try configurations.first?.removeValue(forKeyPath: keyPath)
	}
}

extension KeyPath {
	public static let jiraEmail = KeyPath(
		rawValue: "jira.email",
		description: "The email to use when connecting to JIRA"
	)!
	public static let jiraAccessToken = KeyPath(
		rawValue: "jira.accessToken",
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
