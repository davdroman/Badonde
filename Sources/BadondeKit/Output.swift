import Foundation
import CryptoSwift
import Git
import GitHub

public struct Output: Codable {
	public struct PullRequest: Codable {
		public var title: String
		public var headBranch: String
		public var baseBranch: String
		public var body: String?
		public var assignees: [String]?
		public var labels: [Label]?
		public var milestone: Milestone?
		public var isDraft: Bool
	}

	public var pullRequest: PullRequest
}

extension Output {
	public static func path(for repository: Repository) -> URL {
		let repositoryPathSha1 = repository.topLevelPath.path.sha1()
		return FileManager.default.temporaryDirectory.appendingPathComponent("badonde-output-\(repositoryPathSha1).json")
	}
}
