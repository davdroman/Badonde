import Foundation

public struct Repository: Codable {
	public var defaultBranch: String
	public var shorthand: Shorthand

	enum CodingKeys: String, CodingKey {
		case defaultBranch = "default_branch"
		case shorthand = "full_name"
	}
}
