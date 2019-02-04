import Foundation
import SwiftCLI

extension URLQueryItem {
	init?(name: String, mandatoryValue: String?) {
		guard let value = mandatoryValue else {
			return nil
		}
		self.init(name: name, value: value)
	}
}

extension Array {
	var nilIfEmpty: [Element]? {
		guard !isEmpty else {
			return nil
		}
		return self
	}
}

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

public final class CommandLineTool {
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    public func run() throws {
        let cli = CLI(singleCommand: BadondeCommand())
		_ = cli.go()
    }
}
