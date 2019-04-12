import Foundation
import SwiftCLI

public final class CommandLineTool {

	enum Constant {
		static let name = "badonde"
		static let version = "1.7.0"
		static let description = "Painless PR-ing"
	}

	public init() {}

	public func run(with arguments: [String]? = nil) {
		let cli = CLI(
			name: Constant.name,
			version: Constant.version,
			description: Constant.description,
			commands: [
				AppifyCommand(),
				BurghCommand(),
				ClearCommand(),
				SetFirebaseAuthCommand()
			]
		)
		let exitStatus: Int32
		if let arguments = arguments {
			exitStatus = cli.go(with: arguments)
		} else {
			exitStatus = cli.go()
		}
		exit(exitStatus)
	}
}
