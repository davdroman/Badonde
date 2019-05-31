import Foundation
import struct BadondeKit.Payload
import enum BadondeKit.Log
import struct BadondeKit.Output
import SwiftCLI
import Git

final class BadondefileRunner {
	let repository: Repository

	init(repository: Repository) {
		self.repository = repository
	}

	func run(with payload: Payload) throws -> Output {
		let payloadData = try JSONEncoder().encode(payload)
		try payloadData.write(to: Payload.path(for: repository))

		let exitStatus = try run(
			stdoutCapture: { line in
				line.components(losslesslySeparatedBy: CharacterSet(charactersIn: Log.Symbol.all.joined()))
					.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
					.compactMap { Log(rawValue: $0) }
					.forEach { Logger.printBadondefileLog($0) }
			},
			stderrCapture: { line in
				Logger.fail(line)
			}
		)

		if exitStatus != EXIT_SUCCESS {
			exit(exitStatus)
		}

		let outputData = try Data(contentsOf: Output.path(for: repository))
		let output = try JSONDecoder().decode(Output.self, from: outputData)

		return output
	}

	private func run(stdoutCapture: @escaping (String) -> Void, stderrCapture: @escaping (String) -> Void) throws -> Int32 {
		let output = PipeStream()
		let error = PipeStream()
		let bash = "swift -L ../../Badonde/.build/debug -I ../../Badonde/.build/debug -lBadondeKit Badondefile.swift"
		let task = Task(executable: "/bin/bash", arguments: ["-c", bash], stdout: output, stderr: error)

		let readibilityHandlerForCaptureClosure = { (captureClosure: @escaping (String) -> Void) -> ((FileHandle) -> Void) in
			{ handle in
				guard
					let string = String(data: handle.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
					!string.isEmpty
				else {
					return
				}
				captureClosure(string)
			}
		}

		output.readHandle.readabilityHandler = readibilityHandlerForCaptureClosure(stdoutCapture)
		error.readHandle.readabilityHandler = readibilityHandlerForCaptureClosure(stderrCapture)

		let exitStatus = task.runSync()
		error.closeRead()
		output.closeRead()
		return exitStatus
	}
}

private extension Logger {
	static func printBadondefileLog(_ log: Log) {
		switch log {
		case .step(let description):
			step(description)
		case .info(let description):
			info(description)
		case .warn(let description):
			warn(description)
		case .fail(let description):
			fail(description)
		}
	}
}
