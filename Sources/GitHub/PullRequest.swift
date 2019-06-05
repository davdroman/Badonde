import Foundation

public struct PullRequest {
	public var url: URL
	public var number: Int
	public var title: String
	public var headBranch: Branch
	public var baseBranch: Branch
	public var body: String?
	public var reviewers: [User]
	public var assignees: [User]
	public var labels: [Label]
	public var milestone: Milestone?
}

extension PullRequest: Decodable {
	enum CodingKeys: String, CodingKey {
		case url = "html_url"
		case number
		case title
		case headBranch = "head"
		case baseBranch = "base"
		case body
		case reviewers = "requested_reviewers"
		case assignees
		case labels
		case milestone
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
