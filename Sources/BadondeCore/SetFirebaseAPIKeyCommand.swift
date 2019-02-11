import Foundation
import SwiftCLI

class SetFirebaseAPIKeyCommand: Command {
	let name = "set-firebase-api-key"
	let shortDescription = "Sets Firebase API key for time analytics reporting"
	let apiKey = Parameter()

	func execute() throws {
		let store = ConfigurationStore()
		var additionalConfiguration = store.additionalConfiguration ?? AdditionalConfiguration()
		additionalConfiguration.firebaseApiKey = apiKey.value
		try store.setAdditionalConfiguration(additionalConfiguration)
	}
}
