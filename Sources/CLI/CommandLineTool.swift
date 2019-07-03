import Foundation
import SwiftCLI
import Configuration
import Firebase
import Git

public final class CommandLineTool {
	enum Constant {
		static let name = "badonde"
		static let version = "2.0.1"
	}

	var startDate = Date()
	let startDatePointer: UnsafeMutablePointer<Date>

	public init() {
		startDatePointer = withUnsafeMutablePointer(to: &startDate) { UnsafeMutablePointer<Date>($0) }
	}

	public func run(with arguments: [String]? = nil) {
		_ = try? LegacyConfigurationStore.migrateIfNeeded()

		let cli = CLI(
			name: Constant.name,
			version: Constant.version,
			commands: [
				InitCommand(startDatePointer: startDatePointer),
				EditCommand(startDatePointer: startDatePointer),
				PRCommand(startDatePointer: startDatePointer),
				ConfigCommand(),
			]
		)

		// Intercept CTRL+C exit sequence
		signal(SIGINT) { _ in
			Logger.finish()
			exit(EXIT_SUCCESS)
		}

		cli.handleErrorClosure = { error in
			Logger.fail(error.localizedDescription)
		}

		let exitStatus: Int32
		if let arguments = arguments {
			exitStatus = cli.go(with: arguments)
		} else {
			exitStatus = cli.go()
		}

		if let error = cli.thrownError {
			#if !DEBUG
			do {
				try reportError(error, startDate: startDate)
				Logger.succeed()
			} catch let error {
				Logger.fail(error.localizedDescription)
			}
			#endif
		} else {
			Logger.succeed()

			#if DEBUG
			logElapsedTime(withStartDate: startDate)
			#endif
		}

		Logger.finish()
		exit(exitStatus)
	}

	private func reportError(_ error: Error, startDate: Date) throws {
		let projectPath = try Repository(atPath: FileManager.default.currentDirectoryPath).topLevelPath
		let configuration = try DynamicConfiguration(prioritizedScopes: [.local(path: projectPath), .global])

		guard
			let firebaseProjectId = try configuration.getRawValue(forKeyPath: .firebaseProjectId),
			let firebaseSecretToken = try configuration.getRawValue(forKeyPath: .firebaseSecretToken)
		else {
			return
		}

		Logger.step("Reporting error")
		let reporter = Firebase.DatabaseAPI(firebaseProjectId: firebaseProjectId, firebaseSecretToken: firebaseSecretToken)
		try reporter.post(documentName: "errors", body: error.analyticsData(startDate: startDate, version: Constant.version))
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
