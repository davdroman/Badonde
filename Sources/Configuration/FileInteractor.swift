import Foundation

protocol JSONFileInteractor {
	func read(from path: String) throws -> [String: Any]
	func write(_ rawObject: [String: Any], to path: String) throws
}

extension Configuration {
	final class FileInteractor: JSONFileInteractor {
		func read(from path: String) throws -> [String: Any] {
			let data = try Data(contentsOf: URL(fileURLWithPath: path))
			return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] ?? [:]
		}

		func write(_ rawObject: [String: Any], to path: String) throws {
			let data = try JSONSerialization.data(withJSONObject: rawObject, options: [.prettyPrinted, .sortedKeys])
			try data.write(to: URL(fileURLWithPath: path))
		}
	}
}
