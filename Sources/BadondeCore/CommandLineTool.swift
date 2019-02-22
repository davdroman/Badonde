import Foundation
import SwiftCLI

public final class CommandLineTool {

	public init() {}

	public func run(with arguments: [String]? = nil) {
		let cli = CLI(
			name: "badonde",
			version: "1.3.1",
			description: "Effortless PR creation tool",
			commands: [
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
