import Foundation

public protocol URLContentInitializable {
	init(contentsOf: URL) throws
}

extension String: URLContentInitializable {}

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
