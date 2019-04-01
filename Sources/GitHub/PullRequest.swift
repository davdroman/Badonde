import Foundation

public class PullRequest: Codable {
	public var repositoryShorthand: Repository.Shorthand
	public var baseBranch: String
	public var targetBranch: String
	public var title: String
	public var labels: [String]
	public var milestone: String?

	public init(
		repositoryShorthand: Repository.Shorthand,
		baseBranch: String,
		targetBranch: String,
		title: String,
		labels: [String],
		milestone: String?
	) {
		self.repositoryShorthand = repositoryShorthand
		self.baseBranch = baseBranch
		self.targetBranch = targetBranch
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
			path: "/\(repositoryShorthand)/compare/\(baseBranch)...\(targetBranch)",
			queryItems: [
				URLQueryItem(name: CodingKeys.title.stringValue, mandatoryValue: title.nilIfEmpty),
				URLQueryItem(name: CodingKeys.labels.stringValue, mandatoryValue: labels.nilIfEmpty?.joined(separator: ",")),
				URLQueryItem(name: CodingKeys.milestone.stringValue, mandatoryValue: milestone)
			]
		)
	}
}
