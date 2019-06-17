import Foundation
import Configuration

protocol FileInteractor {
	func contents(atPath path: String) throws -> Data
	func fileExists(atPath path: String) -> Bool
	func createFile(atPath path: String, withIntermediateDirectories createIntermediates: Bool, contents data: Data?, attributes attr: [FileAttributeKey : Any]?) throws
}

extension FileManager: FileInteractor {
	func contents(atPath path: String) throws -> Data {
		return try Data(contentsOf: URL(fileURLWithPath: path))
	}

	func createFile(atPath path: String, withIntermediateDirectories createIntermediates: Bool, contents data: Data?, attributes attr: [FileAttributeKey : Any]? = nil) throws {
		let fileURL = URL(fileURLWithPath: path)
		let folderPath = fileURL.deletingLastPathComponent().path
		if !fileExists(atPath: folderPath) {
			try createDirectory(atPath: folderPath, withIntermediateDirectories: createIntermediates, attributes: nil)
		}
		try data?.write(to: fileURL)
	}
}

final class Initializer {
	struct Credentials {
		var jiraEmail: String
		var jiraApiToken: String
		var githubAccessToken: String
	}

	private let fileInteractor: FileInteractor

	init(fileInteractor: FileInteractor) {
		self.fileInteractor = fileInteractor
	}

	func initializeBadonde(forRepositoryPath path: String, credentials: Credentials) throws {
		try saveCredentials(credentials, to: configuration(forRepositoryPath: path))
	}

	private func configuration(forRepositoryPath path: String) throws -> KeyValueInteractive {
		let scope = Configuration.Scope.local(path: path)
		let fullPath = scope.fullPath
		if !fileInteractor.fileExists(atPath: fullPath) {
			try fileInteractor.createFile(atPath: fullPath, withIntermediateDirectories: true, contents: Data(), attributes: nil)
		}
		return try Configuration(scope: scope)
	}

	private func saveCredentials(_ credentials: Credentials, to configuration: KeyValueInteractive) throws {
		try configuration.setValue(credentials.githubAccessToken, forKeyPath: .githubAccessToken)
		try configuration.setValue(credentials.jiraApiToken, forKeyPath: .jiraApiToken)
		try configuration.setValue(credentials.jiraEmail, forKeyPath: .jiraEmail)
	}
}
