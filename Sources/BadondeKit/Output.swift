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

var output: Output? {
	get {
		do {
			let repository = try Repository()
			let outputPath = Output.path(for: repository)
			let outputData = try Data(contentsOf: outputPath)
			let output = try JSONDecoder().decode(Output.self, from: outputData)
			return output
		} catch {
			return nil
		}
	}
	set {
		guard let newValue = newValue else {
			return
		}
		do {
			let repository = try Repository()
			let outputPath = Output.path(for: repository)
			let outputData = try JSONEncoder().encode(newValue)
			try outputData.write(to: outputPath)
		} catch { }
	}
}

public func title(_ title: String) {
	output?.pullRequest.title = title
}

public func body(_ body: String) {
	output?.pullRequest.body = body
}

public func assignee(_ assignee: String) {
	output?.pullRequest.assignees = output?.pullRequest.assignees ?? [] + [assignee]
}

public func label(_ label: Label) {
	output?.pullRequest.labels = output?.pullRequest.labels ?? [] + [label]
}

public func milestone(_ milestone: Milestone) {
	output?.pullRequest.milestone = milestone
}

public func draft(_ isDraft: Bool) {
	output?.pullRequest.isDraft = isDraft
}
