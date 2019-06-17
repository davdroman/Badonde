import Foundation

protocol JSONFileInteractor {
	func read(from url: URL) throws -> [String: Any]
	func write(_ rawObject: [String: Any], to url: URL) throws
}

extension Configuration {
	final class FileInteractor: JSONFileInteractor {
		func read(from url: URL) throws -> [String: Any] {
			let data = try Data(contentsOf: url)
			return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] ?? [:]
		}

		func write(_ rawObject: [String: Any], to url: URL) throws {
			let data = try JSONSerialization.data(withJSONObject: rawObject, options: [.prettyPrinted, .sortedKeys])
			try data.write(to: url)
		}
	}
}
