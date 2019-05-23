import Foundation
import SwiftCLI
import Git
import Configuration

class SetFirebaseAuthCommand: Command {
	let name = "set-firebase-auth"
	let shortDescription = "[DEPRECATED] Sets Firebase project id & database secret token for analytics reporting"
	lazy var longDescription: String = {
		"""
		Sets Firebase project id & database secret token for analytics reporting

		\(self.deprecationNotice)
		"""
	}()
	lazy var deprecationNotice: String = {
		"""
		`badonde \(self.name)` has been deprecated in favour of `badonde config` and will be removed in version 2.0.0. Please use:

		   badonde config firebase.projectId <value>
		   badonde config firebase.secretToken <value>

		in the future instead.
		"""
	}()
	let projectId = Parameter()
	let secretToken = Parameter()

	func execute() throws {
		Logger.warn(deprecationNotice + "\n")

		Logger.step("Setting Firebase configuration")
		let projectPath = try Repository().topLevelPath
		let configuration = try Configuration(scope: .local(projectPath))
		try configuration.setValue(projectId.value, forKeyPath: .firebaseProjectId)
		try configuration.setValue(secretToken.value, forKeyPath: .firebaseSecretToken)
	}
}
