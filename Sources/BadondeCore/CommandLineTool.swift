import Foundation
import SwiftCLI
import Configuration
import Git

public final class CommandLineTool {

	enum Constant {
		static let name = "badonde"
		static let version = "1.11.0"
		static let description = "Painless PR-ing"
	}

	public init() {}

	public func run(with arguments: [String]? = nil) {
		_ = try? LegacyConfigurationStore.migrateIfNeeded()

		let startDate = Date()

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

		#if !DEBUG
		if let error = cli.thrownError {
			do {
				try reportError(error)
			} catch let error as ProcessError {
				print(error.message ?? error.localizedDescription)
			} catch let error {
				print(error.localizedDescription)
			}
		}
		#endif

		#if DEBUG
		logElapsedTime(withStartDate: startDate)
		#endif

		exit(exitStatus)
	}

	private func reportError(_ error: Error) throws {
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown along the way

		let projectPath = try Repository().topLevelPath
		let configuration = try DynamicConfiguration(prioritizedScopes: [.local(projectPath), .global])

		guard
			let firebaseProjectId = try configuration.getValue(ofType: String.self, forKeyPath: .firebaseProjectId),
			let firebaseSecretToken = try configuration.getValue(ofType: String.self, forKeyPath: .firebaseSecretToken)
		else {
			return
		}

		Logger.step("Reporting error")
		let reporter = ErrorAnalyticsReporter(firebaseProjectId: firebaseProjectId, firebaseSecretToken: firebaseSecretToken)
		try reporter.report(error.analyticsData())

		Logger.finish()
	}

	private func logElapsedTime(withStartDate startDate: Date) {
		let elapsedTime = Date().timeIntervalSince(startDate)

		guard elapsedTime > 1 else {
			return
		}

		let numberFormatter = NumberFormatter()
		numberFormatter.maximumFractionDigits = 2
		let prettyElapsedTime = numberFormatter.string(for: elapsedTime) ?? "?"
		print("Badonde execution took \(prettyElapsedTime)s")
	}
}
