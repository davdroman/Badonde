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

	func execute() throws {
		
	}
}

extension InitCommand {
	enum Error {

	}
}

extension InitCommand.Error: LocalizedError {
	var errorDescription: String? {
		return nil
	}
}
