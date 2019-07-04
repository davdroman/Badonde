import Foundation

protocol TagInteractor {
	func getAllTags(atPath path: String) throws -> String
}

public struct Tag: Equatable, Codable {
	public var name: String
}

extension Tag {
	static var interactor: TagInteractor = SwiftCLI()

	public static func getAll(atPath path: String) throws -> [Tag] {
		return try interactor.getAllTags(atPath: path)
			.components(separatedBy: "\n")
			.map { Tag(name: $0) }
	}
}
