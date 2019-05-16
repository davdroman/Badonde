import Foundation
import SwiftCLI
import Git
import Configuration

class ClearCommand: Command {
	let name = "clear"
	let shortDescription = "[DEPRECATED] Clears credentials"
	lazy var longDescription: String = {
		return """
		Clears credentials

		\(self.deprecationNotice)
		"""
	}()
	lazy var deprecationNotice: String = {
		"""
		`badonde \(self.name)` has been deprecated in favour of `badonde config` and will be removed in version 2.0.0. Please use:

		   badonde config --unset jira.email
		   badonde config --unset jira.apiToken
		   badonde config --unset github.accessToken

		in the future instead.
		"""
	}()

	func execute() throws {
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown along the way

		Logger.warn(deprecationNotice + "\n")

		Logger.step("Removing existing configuration")
		let projectPath = try Repository().topLevelPath
		let configuration = try Configuration(scope: .local(projectPath))
		try configuration.removeValue(forKeyPath: .jiraEmail)
		try configuration.removeValue(forKeyPath: .jiraApiToken)
		try configuration.removeValue(forKeyPath: .githubAccessToken)

		Logger.finish()
	}
}
