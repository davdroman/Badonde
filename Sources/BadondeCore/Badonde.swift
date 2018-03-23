import Foundation
import FileKit
import ShellOut

public final class Badonde {
	private let arguments: [String]

	public init(arguments: [String] = CommandLine.arguments) {
		self.arguments = arguments
	}

	public func run() throws {
		let branchName = try shellOut(to: "git rev-parse --symbolic-full-name --abbrev-ref HEAD")
		let prCreationURL = "https://github.com/asosteam/asos-native-ios/compare/develop...\(branchName)?expand=1"
		try shellOut(to: "open \(prCreationURL)")
	}
}
