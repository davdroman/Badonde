import Foundation

protocol JSONFileInteractor {
	func read(from url: URL) throws -> [String: Any]
	func write(_ rawObject: [String: Any], to url: URL) throws
}

extension Configuration {
	final class FileInteractor: JSONFileInteractor {
		func read(from url: URL) throws -> [String: Any] {
			// TODO: remove when `badonde init` is implemented.
			// https://github.com/davdroman/Badonde/issues/79
			try createEmptyFileIfNeeded(for: url)
			let data = try Data(contentsOf: url)
			return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] ?? [:]
		}

		func write(_ rawObject: [String: Any], to url: URL) throws {
			let data = try JSONSerialization.data(withJSONObject: rawObject, options: [.prettyPrinted, .sortedKeys])
			try data.write(to: url)
		}

		private func createEmptyFileIfNeeded(for url: URL) throws {
			if !FileManager.default.fileExists(atPath: url.path) {
				let fileDirectoryURL = url.deletingLastPathComponent()
				try FileManager.default.createDirectory(
					at: fileDirectoryURL,
					withIntermediateDirectories: true,
					attributes: nil
				)
				try Data().write(to: url)
			}
		}
	}
}
