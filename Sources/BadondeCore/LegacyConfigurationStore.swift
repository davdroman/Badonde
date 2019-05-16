import Foundation

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
