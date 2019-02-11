import Foundation
import SwiftCLI

public final class CommandLineTool {
	private let arguments: [String]

	public init(arguments: [String] = CommandLine.arguments) {
		self.arguments = arguments
	}

	public func run() throws {
		let cli = CLI(
			name: "badonde",
			version: "1.0.0",
			description: "Effortless PR creation too",
			commands: [
				BurghCommand(),
				ClearCommand(),
				SetFirebaseAPIKeyCommand()
			]
		)
		_ = cli.go()
	}
}
