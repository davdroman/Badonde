import Foundation
import SwiftCLI

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
		   badonde config --unset jira.accessToken
		   badonde config --unset github.accessToken

		in the future instead.
		"""
	}()

	func execute() throws {
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown along the way

		Logger.warn(deprecationNotice + "\n")

		Logger.step("Removing existing configuration")
		let store = LegacyConfigurationStore()
		guard store.configuration != nil else {
			Logger.info("No existing configuration found")
			return
		}
		try store.clearConfiguration()

		Logger.finish()
	}
}
