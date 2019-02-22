import Foundation
import SwiftCLI

public final class CommandLineTool {

	public init() {}

	public func run() throws {
		let cli = CLI(
			name: "badonde",
			version: "1.2.2",
			description: "Effortless PR creation too",
			commands: [
				BurghCommand(),
				ClearCommand(),
				SetFirebaseAuthCommand()
			]
		)
		_ = cli.go()
	}
}
