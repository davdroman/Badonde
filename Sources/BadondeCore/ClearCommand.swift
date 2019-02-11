import Foundation
import SwiftCLI

class ClearCommand: Command {
	let name = "clear"
	let shortDescription = "Clears credentials"

	func execute() throws {
		let store = ConfigurationStore()
		guard store.configuration != nil else {
			return
		}
		try store.clearConfiguration()
	}
}
