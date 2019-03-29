import Foundation
import SwiftCLI

class ClearCommand: Command {
	let name = "clear"
	let shortDescription = "Clears credentials"

	func execute() throws {
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown along the way

		Logger.step("Removing existing configuration")
		let store = ConfigurationStore()
		guard store.configuration != nil else {
			Logger.info("No existing configuration found")
			return
		}
		try store.clearConfiguration()

		Logger.finish()
	}
}
