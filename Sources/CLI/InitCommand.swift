import Foundation
import SwiftCLI
import Configuration
import Core
import Git

final class InitCommand: Command {
	let name = "init"
	let shortDescription = "Sets up Badonde for your project"
	let longDescription =
		"""
		Sets up Badonde for your project.

		When run inside a Git repository, this command will set up Badonde by:

		  • Creating a config file at '.badonde/config.json'.
		  • Prompting for GitHub and Jira credentials and adding them to the config.
		  • Adding '.badonde' to gitignore.
		  • Creating a basic Badondefile.

		If either of these steps have previously ocurred, said step will be skipped.
		"""

	let startDatePointer: UnsafeMutablePointer<Date>

	init(startDatePointer: UnsafeMutablePointer<Date>) {
		self.startDatePointer = startDatePointer
	}

	func execute() throws {
		let fileManager = FileManager.default
		let repositoryPath = try Repository(atPath: fileManager.currentDirectoryPath).topLevelPath

		let configuration = try? DynamicConfiguration(prioritizedScopes: [.local(path: repositoryPath), .global])
		let credentials = try Initializer.Credentials(
			githubAccessToken: configuration?.getRawValue(forKeyPath: .githubAccessToken) ?? Prompter.prompt(.githubAccessToken),
			jiraEmail: configuration?.getRawValue(forKeyPath: .jiraEmail) ?? Prompter.prompt(.jiraEmail),
			jiraApiToken: configuration?.getRawValue(forKeyPath: .jiraApiToken) ?? Prompter.prompt(.jiraApiToken)
		)

		// Reset start date because credentials might've been prompted
		// and analytics data about tool performance might be skewed as a result.
		startDatePointer.pointee = Date()

		try Initializer(fileInteractor: fileManager).initializeBadonde(forRepositoryPath: repositoryPath, credentials: credentials)
	}
}
