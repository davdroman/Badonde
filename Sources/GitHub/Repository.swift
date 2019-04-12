import Foundation

public struct Repository: Codable {
	public let defaultBranch: String

	private enum CodingKeys: String, CodingKey {
		case defaultBranch = "default_branch"
	}
}
