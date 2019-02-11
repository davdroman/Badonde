import Foundation

struct Configuration: Codable {
	var jiraEmail: String
	var jiraApiToken: String
	var githubAccessToken: String
}

struct AdditionalConfiguration: Codable {
	var firebaseProjectId: String?
	var firebaseSecretToken: String?
}

final class ConfigurationStore {

	private static let folderPath = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent(".badonde", isDirectory: true)
	private static let configurationFilePath = ConfigurationStore.folderPath.appendingPathComponent("config.json")
	private static let additionalConfigurationFilePath = ConfigurationStore.folderPath.appendingPathComponent("add_config.json")

	private(set) var configuration: Configuration?
	private(set) var additionalConfiguration: AdditionalConfiguration?

	init() {
		configuration = try? Configuration.read(from: ConfigurationStore.configurationFilePath)
		additionalConfiguration = try? AdditionalConfiguration.read(from: ConfigurationStore.additionalConfigurationFilePath)
	}

	func setConfiguration(_ configuration: Configuration) throws {
		try createConfigurationFolderIfNeeded()
		try configuration.write(to: ConfigurationStore.configurationFilePath)
		self.configuration = configuration
	}

	func clearConfiguration() throws {
		try FileManager.default.removeItem(at: ConfigurationStore.configurationFilePath)
		self.configuration = nil
	}

	func setAdditionalConfiguration(_ configuration: AdditionalConfiguration) throws {
		try createConfigurationFolderIfNeeded()
		try configuration.write(to: ConfigurationStore.additionalConfigurationFilePath)
		self.additionalConfiguration = configuration
	}

	private func createConfigurationFolderIfNeeded() throws {
		let fileManager = FileManager.default
		let folderPath = ConfigurationStore.folderPath

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
