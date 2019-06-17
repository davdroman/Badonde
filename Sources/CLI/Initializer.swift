import Foundation
import Configuration
import Core

protocol FileInteractor {
	func contents(atPath path: String) throws -> Data
	func fileExists(atPath path: String) -> Bool
	func createFile(atPath path: String, withIntermediateDirectories createIntermediates: Bool, contents data: Data?, attributes attr: [FileAttributeKey: Any]?) throws
}

extension FileManager: FileInteractor {
	func contents(atPath path: String) throws -> Data {
		return try Data(contentsOf: URL(fileURLWithPath: path))
	}

	func createFile(atPath path: String, withIntermediateDirectories createIntermediates: Bool, contents data: Data?, attributes attr: [FileAttributeKey: Any]? = nil) throws {
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
		var githubAccessToken: String
		var jiraEmail: String
		var jiraApiToken: String
	}

	private let fileInteractor: FileInteractor

	init(fileInteractor: FileInteractor) {
		self.fileInteractor = fileInteractor
	}

	func initializeBadonde(forRepositoryPath path: String, credentials: Credentials) throws {
		try saveCredentials(credentials, to: configuration(forRepositoryPath: path))
		try updateGitignore(forRepositoryPath: path)
		try createBadondefile(forRepositoryPath: path)
	}

	private func configuration(forRepositoryPath path: String) throws -> Configuration {
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

	private func updateGitignore(forRepositoryPath path: String) throws {
		let gitignorePath = URL(fileURLWithPath: path).appendingPathComponent(".gitignore").path
		let gitignoreContents = (try? String(contentsOfFile: gitignorePath)) ?? ""

		guard !gitignoreContents.contains(".badonde") else {
			return
		}

		let newGitignoreContents = gitignoreContents
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.appending("\n\n")
			.appending(".badonde")
			.trimmingCharacters(in: .whitespacesAndNewlines)

		try fileInteractor.createFile(
			atPath: gitignorePath,
			withIntermediateDirectories: true,
			contents: Data(newGitignoreContents.utf8),
			attributes: nil
		)
	}

	private func createBadondefile(forRepositoryPath path: String) throws {
		if (try? BadondefileRunner(forRepositoryPath: path).badondefilePath()) != nil {
			return
		}

		let badondefilePath = URL(fileURLWithPath: path).appendingPathComponent("Badondefile.swift").path
		let badondefileContents = """
		import BadondeKit

		let badonde = Badonde()

		// Edit me by running 'badonde edit' from your project folder.
		"""

		try fileInteractor.createFile(
			atPath: badondefilePath,
			withIntermediateDirectories: false,
			contents: Data(badondefileContents.utf8),
			attributes: nil
		)
	}
}
