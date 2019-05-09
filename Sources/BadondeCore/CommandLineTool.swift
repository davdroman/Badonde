import Foundation
import SwiftCLI

public final class CommandLineTool {

	enum Constant {
		static let name = "badonde"
		static let version = "1.10.0"
		static let description = "Painless PR-ing"
	}

	public init() {}

	public let startDate = Date()

	public func run(with arguments: [String]? = nil) {
		let cli = CLI(
			name: Constant.name,
			version: Constant.version,
			description: Constant.description,
			commands: [
				AppifyCommand(),
				BurghCommand(startDate: startDate),
				ClearCommand(),
				ConfigCommand(),
				SetFirebaseAuthCommand()
			]
		)

		let exitStatus: Int32
		if let arguments = arguments {
			exitStatus = cli.go(with: arguments)
		} else {
			exitStatus = cli.go()
		}

		#if DEBUG
		let elapsedTime = Date().timeIntervalSince(startDate)
		if elapsedTime > 1 {
			let numberFormatter = NumberFormatter()
			numberFormatter.maximumFractionDigits = 2
			let prettyElapsedTime = numberFormatter.string(for: elapsedTime) ?? "?"
			print("Badonde execution took \(prettyElapsedTime)s")
		}
		#endif

		exit(exitStatus)
	}
}
