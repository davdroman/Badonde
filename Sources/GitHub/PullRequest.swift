import Foundation

public class PullRequest: Codable {
	public var repositoryShorthand: Repository.Shorthand
	public var baseBranch: String
	public var headBranch: String
	public var title: String
	public var labels: [String]
	public var milestone: String?

	public init(
		repositoryShorthand: Repository.Shorthand,
		baseBranch: String,
		headBranch: String,
		title: String,
		labels: [String],
		milestone: String?
	) {
		self.repositoryShorthand = repositoryShorthand
		self.baseBranch = baseBranch
		self.headBranch = headBranch
		self.title = title
		self.labels = labels
		self.milestone = milestone
	}
}

extension PullRequest {
	public func url() throws -> URL {
		return try URL(
			scheme: "https",
			host: "github.com",
			path: "/\(repositoryShorthand)/compare/\(baseBranch)...\(headBranch)",
			queryItems: [
				URLQueryItem(name: CodingKeys.title.stringValue, mandatoryValue: title.nilIfEmpty),
				URLQueryItem(name: CodingKeys.labels.stringValue, mandatoryValue: labels.nilIfEmpty?.joined(separator: ",")),
				URLQueryItem(name: CodingKeys.milestone.stringValue, mandatoryValue: milestone)
			]
		)
	}
}
