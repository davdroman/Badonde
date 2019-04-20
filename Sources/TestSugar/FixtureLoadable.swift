import Foundation

public protocol URLContentInitializable {
	init(contentsOf url: URL) throws
}

extension String: URLContentInitializable {}

extension Data: URLContentInitializable {
	public init(contentsOf url: URL) throws {
		self = try Data(contentsOf: url, options: [])
	}
}

extension Dictionary {
	init(contentsOf url: URL) throws {
		let data = try Data(contentsOf: url)
		let object = try JSONSerialization.jsonObject(with: data, options: [])
		guard let _self = object as? [Key: Value] else {
			throw DecodingError.typeMismatch(
				[Key: Value].self,
				DecodingError.Context(
					codingPath: [],
					debugDescription: "Decoded fixture did not match expected type"
				)
			)
		}
		self = _self
	}
}

extension Array {
	init(contentsOf url: URL) throws {
		let data = try Data(contentsOf: url)
		let object = try JSONSerialization.jsonObject(with: data, options: [])
		guard let _self = object as? [Element] else {
			throw DecodingError.typeMismatch(
				[Element].self,
				DecodingError.Context(
					codingPath: [],
					debugDescription: "Decoded fixture did not match expected type"
				)
			)
		}
		self = _self
	}
}

public protocol FixtureLoadable {
	var sourceFilePath: String { get }
	func load<T: URLContentInitializable>(as type: T.Type) throws -> T
}

public extension FixtureLoadable where Self: RawRepresentable, Self.RawValue == String {
	private var fixtureURL: URL {
		let sourceFileURL = URL(fileURLWithPath: sourceFilePath)
		let fileNameWithoutExtension = sourceFileURL.lastPathComponent.prefix(while: { $0 != "." })
		return URL(fileURLWithPath: sourceFilePath)
			.deletingLastPathComponent()
			.appendingPathComponent("\(fileNameWithoutExtension)Fixtures/\(rawValue).txt")
	}

	func load<T: URLContentInitializable>(as type: T.Type) throws -> T {
		return try T(contentsOf: fixtureURL)
	}
}
