import Foundation

public struct PullRequest {
	public var url: URL
	public var number: Int
	public var assignees: [User]
	public var requestedReviewers: [User]
	public var headBranch: Branch
	public var baseBranch: Branch
}

extension PullRequest: Decodable {
	enum CodingKeys: String, CodingKey {
		case url = "html_url"
		case number
		case assignees
		case requestedReviewers = "requested_reviewers"
		case headBranch = "head"
		case baseBranch = "base"
	}
}

extension PullRequest {
	public struct Branch {
		public var label: String
		public var reference: String
	}
}

extension PullRequest.Branch: Codable {
	enum CodingKeys: String, CodingKey {
		case label
		case reference = "ref"
	}
}
