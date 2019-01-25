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

class PullRequestURLFactory: Codable {

	var repositoryShorthand: String
	var baseBranch: String?
	var targetBranch: String?
	var title: String?
	var labels: [String]?

	init(repositoryShorthand: String) {
		self.repositoryShorthand = repositoryShorthand
	}

	var url: URL? {
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = "github.com"
		urlComponents.path = urlPath

		urlComponents.queryItems = [
			URLQueryItem(name: CodingKeys.title.stringValue, mandatoryValue: title),
			URLQueryItem(name: CodingKeys.labels.stringValue, mandatoryValue: labels?.joined(separator: ","))
		].compactMap({ $0 }).nilIfEmpty

		return urlComponents.url
	}

	private var urlPath: String {
		var path = "/\(repositoryShorthand)/compare"

		switch (baseBranch, targetBranch) {
		case let (base?, target?):
			path.append(contentsOf: "/\(base)...\(target)")
		case let (nil, target?):
			path.append(contentsOf: "/\(target)")
		case let (base?, nil):
			path.append(contentsOf: "/\(base)...")
		case (nil, nil):
			path.append(contentsOf: "/")
		}

		return path
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
