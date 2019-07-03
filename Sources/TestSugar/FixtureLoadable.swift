import Foundation

public protocol FilePathInitializable {
	init(contentsOfFile path: String) throws
}

extension String: FilePathInitializable {}

extension Data: FilePathInitializable {
	public init(contentsOfFile path: String) throws {
		self = try Data(contentsOf: URL(fileURLWithPath: path))
	}
}

extension Dictionary: FilePathInitializable {
	public init(contentsOfFile path: String) throws {
		let data = try Data(contentsOfFile: path)
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

extension Array: FilePathInitializable {
	public init(contentsOfFile path: String) throws {
		let data = try Data(contentsOfFile: path)
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

	func load<T: FilePathInitializable>(as type: T.Type) throws -> T
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
	var path: String {
		let sourceFileURL = URL(fileURLWithPath: sourceFilePath)
		let fileNameWithoutExtension = sourceFileURL.lastPathComponent.prefix(while: { $0 != "." })
		return sourceFileURL
			.deletingLastPathComponent()
			.appendingPathComponent("\(fileNameWithoutExtension)\(fixtureFolderSuffix)/\(rawValue).\(fixtureFileExtension)")
			.path
	}

	func load<T: FilePathInitializable>(as type: T.Type) throws -> T {
		return try T(contentsOfFile: path)
	}
}
