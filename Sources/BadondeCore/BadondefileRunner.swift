import Foundation
import SwiftCLI
import struct BadondeKit.Payload
import enum BadondeKit.Log
import struct BadondeKit.Output
import Git

final class BadondefileRunner {
	let repository: Repository

	init(repository: Repository) {
		self.repository = repository
	}

	func run(with payload: Payload) throws -> Output {
		let payloadData = try JSONEncoder().encode(payload)
		try payloadData.write(to: Payload.path(for: repository))

		try run(
			stdoutCapture: { line in
				line.components(losslesslySeparatedBy: CharacterSet(charactersIn: Log.Symbol.all.joined()))
					.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
					.compactMap { Log(rawValue: $0) }
					.forEach { Logger.logBadondefileLog($0) }
			},
			stderrCapture: { line in
				Logger.fail(line)
			}
		)

		let outputData = try Data(contentsOf: Output.path(for: repository))
		let output = try JSONDecoder().decode(Output.self, from: outputData)
		return output
	}

	private func run(stdoutCapture: @escaping (String) -> Void, stderrCapture: @escaping (String) -> Void) throws {
		let output = PipeStream()
		let error = PipeStream()
		let bash = try ["swift", bashLibraryPathArgument("-L"), bashLibraryPathArgument("-I"), "-lBadondeKit", bashBadondefilePath()].joined(separator: " ")
		let task = Task(executable: "/bin/bash", arguments: ["-c", bash], stdout: output, stderr: error)

		output.readHandle.readabilityHandler = { handle in
			guard
				let string = String(data: handle.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
				!string.isEmpty
			else {
				return
			}
			stdoutCapture(string)
		}

		let exitStatus = task.runSync()

		let stderrContent = error.readAll().trimmingCharacters(in: .whitespacesAndNewlines)
		if !stderrContent.isEmpty {
			stderrCapture(stderrContent)
		}

		if exitStatus != EXIT_SUCCESS {
			exit(exitStatus)
		}
	}

	private func bashLibraryPathArgument(_ name: String) -> String {
		return [name, bashLibrariesPath].joined(separator: " ")
	}

	private lazy var bashLibrariesPath: String = {
		let path: String
		#if DEBUG
		path = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path
		#else
		path = "/usr/local/lib/badonde"
		#endif
		return "'\(path)'"
	}()

	private func bashBadondefilePath() throws -> String {
		let bash = "find '\(repository.topLevelPath.path)' -type f -iname 'Badondefile.swift'"
		guard let path = try capture(bash: bash).stdout.components(separatedBy: .newlines).first else {
			throw Error.badondefileNotFound
		}
		return "'\(path)'"
	}
}

extension BadondefileRunner {
	public enum Error: LocalizedError {
		case badondefileNotFound

		public var errorDescription: String? {
			switch self {
			case .badondefileNotFound:
				return "Could not find Badondefile.swift within current repository"
			}
		}
	}
}

private extension Logger {
	static func logBadondefileLog(_ log: Log) {
		let indentationLevel = 3
		switch log {
		case .step(let description):
			step(indentationLevel: indentationLevel, description)
		case .info(let description):
			info(indentationLevel: indentationLevel, description)
		case .warn(let description):
			warn(indentationLevel: indentationLevel, description)
		case .fail(let description):
			fail(indentationLevel: indentationLevel, description)
		}
	}
}
