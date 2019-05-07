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

final class MultiscopeConfiguration: KeyValueInteractive {
	let localConfiguration: KeyValueInteractive
	let globalConfiguration: KeyValueInteractive

	init() throws {
		localConfiguration = try Configuration(scope: .local)
		globalConfiguration = try Configuration(scope: .global)
	}

	func getValue<T>(ofType type: T.Type, forKeyPath keyPath: KeyPath) throws -> T? {
		let localValue = try localConfiguration.getValue(ofType: T.self, forKeyPath: keyPath)
		let globalValue = try globalConfiguration.getValue(ofType: T.self, forKeyPath: keyPath)
		return globalValue ?? localValue
	}

	func setValue<T>(_ value: T, forKeyPath keyPath: KeyPath) throws {
		try localConfiguration.setValue(value, forKeyPath: keyPath)
	}

	func getRawValue(forKeyPath keyPath: KeyPath) throws -> String? {
		let localValue = try localConfiguration.getRawValue(forKeyPath: keyPath)
		let globalValue = try globalConfiguration.getRawValue(forKeyPath: keyPath)
		return globalValue ?? localValue
	}

	func setRawValue(_ value: String, forKeyPath keyPath: KeyPath) throws {
		try localConfiguration.setRawValue(value, forKeyPath: keyPath)
	}

	func removeValue(forKeyPath keyPath: KeyPath) throws {
		try localConfiguration.removeValue(forKeyPath: keyPath)
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
