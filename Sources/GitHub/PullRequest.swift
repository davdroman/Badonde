import Foundation

public struct PullRequest {
	public var url: URL
	public var number: Int
}

extension PullRequest: Decodable {
	enum CodingKeys: String, CodingKey {
		case url = "html_url"
		case number
	}
}
