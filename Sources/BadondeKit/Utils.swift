import Foundation
import SwiftCLI

/// A set of convenience script utilities for easily performing recurrent
/// actions without the overhead of native error handling/optionality.
public enum Utils {
	/// Reads a file and returns its contents.
	///
	/// - Parameter filePath: the file's path.
	/// - Returns: the UTF-8 contents of the file.
	public static func readFile(_ filePath: String) -> String {
		guard let data = FileManager.default.contents(atPath: filePath) else {
			Logger.fail("Could not get the contents of '\(filePath)'")
			exit(EXIT_FAILURE)
		}

		guard let content = String(data: data, encoding: .utf8) else {
			print("Could not read UTF-8 contents of '\(filePath)', is it a binary?")
			exit(EXIT_FAILURE)
		}

		return content
	}

	/// Executes a bash command and returns its output.
	///
	/// - Parameter bash: the bash command to be executed in the directory
	///   where the Badondefile is located.
	/// - Returns: the output returned by the command through stdout.
	public func exec(_ bash: String) -> String {
		return trySafely { try Task.capture(bash: bash).stdout }
	}
}
