import Foundation
import SwiftCLI

public enum Utils {
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

	public func exec(_ bash: String) -> String {
		return trySafely { try Task.capture(bash: bash).stdout }
	}
}
