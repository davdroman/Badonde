import Foundation

public struct Repository: Codable {
	public typealias Shorthand = String // TODO: make type and value safe struct

	public let defaultBranch: String

	private enum CodingKeys: String, CodingKey {
		case defaultBranch = "default_branch"
	}
}
