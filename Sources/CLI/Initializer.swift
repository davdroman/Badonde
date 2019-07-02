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
		var jiraEmail: String?
		var jiraApiToken: String?
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
		let globalScopePath = Configuration.Scope.global.fullPath
		if !fileInteractor.fileExists(atPath: globalScopePath) {
			try fileInteractor.createFile(atPath: globalScopePath, withIntermediateDirectories: true, contents: Data(), attributes: nil)
		}

		let localScope = Configuration.Scope.local(path: path)
		let localScopePath = localScope.fullPath
		if !fileInteractor.fileExists(atPath: localScopePath) {
			try fileInteractor.createFile(atPath: localScopePath, withIntermediateDirectories: true, contents: Data(), attributes: nil)
		}
		return try Configuration(scope: localScope)
	}

	private func saveCredentials(_ credentials: Credentials, to configuration: KeyValueInteractive) throws {
		try configuration.setRawValue(credentials.githubAccessToken, forKeyPath: .githubAccessToken)
		if let jiraEmail = credentials.jiraEmail, let jiraApiToken = credentials.jiraApiToken {
			try configuration.setRawValue(jiraEmail, forKeyPath: .jiraEmail)
			try configuration.setRawValue(jiraApiToken, forKeyPath: .jiraApiToken)
		}
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
		if (try? Badondefile.path(forRepositoryPath: path)) != nil {
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
