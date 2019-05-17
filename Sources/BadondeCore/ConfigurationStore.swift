import Foundation
import Configuration
import Git
import SwiftCLI

struct LegacyConfiguration: Codable {
	var jiraEmail: String
	var jiraApiToken: String
	var githubAccessToken: String
}

struct LegacyAdditionalConfiguration: Codable {
	var firebaseProjectId: String?
	var firebaseSecretToken: String?
}

final class LegacyConfigurationStore {

	private static let folderPath = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent(".badonde", isDirectory: true)
	private static let configurationFilePath = LegacyConfigurationStore.folderPath.appendingPathComponent("config.json")
	private static let additionalConfigurationFilePath = LegacyConfigurationStore.folderPath.appendingPathComponent("add_config.json")

	private(set) var configuration: LegacyConfiguration?
	private(set) var additionalConfiguration: LegacyAdditionalConfiguration?

	init() {
		configuration = try? LegacyConfiguration.read(from: LegacyConfigurationStore.configurationFilePath)
		additionalConfiguration = try? LegacyAdditionalConfiguration.read(from: LegacyConfigurationStore.additionalConfigurationFilePath)
	}

	func setConfiguration(_ configuration: LegacyConfiguration) throws {
		try createConfigurationFolderIfNeeded()
		try configuration.write(to: LegacyConfigurationStore.configurationFilePath)
		self.configuration = configuration
	}

	func clearConfiguration() throws {
		try FileManager.default.removeItem(at: LegacyConfigurationStore.configurationFilePath)
		self.configuration = nil
	}

	func setAdditionalConfiguration(_ configuration: LegacyAdditionalConfiguration) throws {
		try createConfigurationFolderIfNeeded()
		try configuration.write(to: LegacyConfigurationStore.additionalConfigurationFilePath)
		self.additionalConfiguration = configuration
	}

	class func migrateIfNeeded() throws {
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown along the way

		// Append .badonde to .gitignore if not present.
		// Remove along with whole class when `badonde init` is implemented.
		// https://github.com/davdroman/Badonde/pull/79
		let projectPath = try Repository().topLevelPath
		let gitignorePath = projectPath.appendingPathComponent(".gitignore")
		let gitignoreContents = try String(contentsOf: gitignorePath)
		if !gitignoreContents.contains(".badonde") {
			_ = try capture(bash: "echo >> \(gitignorePath.path)")
			_ = try capture(bash: "echo '.badonde' >> \(gitignorePath.path)")
		}

		let store = LegacyConfigurationStore()
		let migrationNeeded = store.configuration != nil || store.additionalConfiguration != nil

		guard migrationNeeded else {
			return
		}

		Logger.step("Legacy configuration detected, migrating...")

		let configuration = try Configuration(scope: .local(projectPath))

		if let legacyConfiguration = store.configuration {
			try configuration.setValue(legacyConfiguration.githubAccessToken, forKeyPath: .githubAccessToken)
			try configuration.setValue(legacyConfiguration.jiraEmail, forKeyPath: .jiraEmail)
			try configuration.setValue(legacyConfiguration.jiraApiToken, forKeyPath: .jiraApiToken)
		}

		if let firebaseProjectId = store.additionalConfiguration?.firebaseProjectId {
			try configuration.setValue(firebaseProjectId, forKeyPath: .firebaseProjectId)
		}

		if let firebaseSecretToken = store.additionalConfiguration?.firebaseSecretToken {
			try configuration.setValue(firebaseSecretToken, forKeyPath: .firebaseSecretToken)
		}

		try FileManager.default.removeItem(at: LegacyConfigurationStore.folderPath)

		Logger.finish()
	}

	private func createConfigurationFolderIfNeeded() throws {
		let fileManager = FileManager.default
		let folderPath = LegacyConfigurationStore.folderPath

		guard !fileManager.fileExists(atPath: folderPath.absoluteString) else {
			return
		}

		try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
	}
}

private extension Decodable {
	static func read(from url: URL) throws -> Self {
		let data = try Data(contentsOf: url)
		return try JSONDecoder().decode(Self.self, from: data)
	}
}

private extension Encodable {
	func write(to url: URL) throws {
		let data = try JSONEncoder().encode(self)
		try data.write(to: url)
	}
}
