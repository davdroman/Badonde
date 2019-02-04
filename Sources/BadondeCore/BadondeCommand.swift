import Foundation
import SwiftCLI

class BadondeCommand: Command {
	let name = ""

	enum Error: Swift.Error {
		case urlInvalid
	}

	func execute() throws {
		guard let currentBranch = try? capture(bash: "git rev-parse --abbrev-ref HEAD").stdout else {
			return
		}

		let pullRequestURLFactory = PullRequestURLFactory(repositoryShorthand: "asosteam/asos-native-ios")
		pullRequestURLFactory.baseBranch = "develop"
		pullRequestURLFactory.targetBranch = currentBranch
		pullRequestURLFactory.title = "Something in the air"
		pullRequestURLFactory.labels = ["Bug", "Back in Stock"]

		guard let pullRequestURL = pullRequestURLFactory.url else {
			throw Error.urlInvalid
		}

		try run(bash: "open \"\(pullRequestURL)\"")

		stdout <<< currentBranch
	}
}
