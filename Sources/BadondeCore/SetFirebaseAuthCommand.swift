import Foundation
import SwiftCLI

class SetFirebaseAuthCommand: Command {
	let name = "set-firebase-auth"
	let shortDescription = "Sets Firebase project id & database secret token for analytics reporting"
	let projectId = Parameter()
	let secretToken = Parameter()

	func execute() throws {
		let store = ConfigurationStore()
		var additionalConfiguration = store.additionalConfiguration ?? AdditionalConfiguration()
		additionalConfiguration.firebaseProjectId = projectId.value
		additionalConfiguration.firebaseSecretToken = secretToken.value
		try store.setAdditionalConfiguration(additionalConfiguration)
	}
}
