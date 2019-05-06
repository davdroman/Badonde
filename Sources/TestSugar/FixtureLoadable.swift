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
	var fixtureFolderSuffix: String { get }
	var fixtureFileExtension: String { get }
	func load<T: URLContentInitializable>(as type: T.Type) throws -> T
}

extension FixtureLoadable {
	public var fixtureFolderSuffix: String {
		return "Fixtures"
	}

	public var fixtureFileExtension: String {
		return "json"
	}
}

public extension FixtureLoadable where Self: RawRepresentable, Self.RawValue == String {
	var url: URL {
		let sourceFileURL = URL(fileURLWithPath: sourceFilePath)
		let fileNameWithoutExtension = sourceFileURL.lastPathComponent.prefix(while: { $0 != "." })
		return URL(fileURLWithPath: sourceFilePath)
			.deletingLastPathComponent()
			.appendingPathComponent("\(fileNameWithoutExtension)\(fixtureFolderSuffix)/\(rawValue).\(fixtureFileExtension)")
	}

	func load<T: URLContentInitializable>(as type: T.Type) throws -> T {
		return try T(contentsOf: url)
	}
}
