import Foundation

public struct PullRequest {
	public var url: URL
	public var number: Int
	public var assignees: [User]
	public var requestedReviewers: [User]
}

extension PullRequest: Decodable {
	enum CodingKeys: String, CodingKey {
		case url = "html_url"
		case number
		case assignees
		case requestedReviewers = "requested_reviewers"
	}
}
