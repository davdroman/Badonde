import Foundation

public class PullRequest: Codable {
	public var repositoryShorthand: String
	public var baseBranch: String?
	public var targetBranch: String?
	public var title: String?
	public var labels: [String]?
	public var milestone: String?

	public init(repositoryShorthand: String) {
		self.repositoryShorthand = repositoryShorthand
	}
}

extension PullRequest {
	public func url() throws -> URL {
		return try URL(
			scheme: "https",
			host: "github.com",
			path: urlPath,
			queryItems: [
				URLQueryItem(name: CodingKeys.title.stringValue, mandatoryValue: title),
				URLQueryItem(name: CodingKeys.labels.stringValue, mandatoryValue: labels?.joined(separator: ",")),
				URLQueryItem(name: CodingKeys.milestone.stringValue, mandatoryValue: milestone)
			]
		)
	}

	private var urlPath: String {
		var path = "/\(repositoryShorthand)/compare"

		switch (baseBranch, targetBranch) {
		case let (base?, target?):
			path.append(contentsOf: "/\(base)...\(target)")
		case let (nil, target?):
			path.append(contentsOf: "/\(target)")
		case let (base?, nil):
			path.append(contentsOf: "/\(base)...")
		case (nil, nil):
			path.append(contentsOf: "/")
		}

		return path
	}
}
