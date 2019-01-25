import Foundation
import SwiftCLI

class BadondeCommand: Command {
	let name = ""
	
	func execute() throws {
		guard let currentBranch = try? capture(bash: "git rev-parse --abbrev-ref HEAD").stdout else {
			return
		}

		try run(bash: "open \"https://github.com/asosteam/asos-native-ios/compare/\(currentBranch)?expand=1\"")

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
