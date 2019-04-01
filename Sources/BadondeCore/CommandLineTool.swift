import Foundation
import SwiftCLI

public final class CommandLineTool {

	enum Constant {
		static let name = "badonde"
		static let version = "1.6.0"
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
		if let arguments = arguments {
			_ = cli.go(with: arguments)
		} else {
			_ = cli.go()
		}
	}
}
