import Foundation
import CryptoSwift
import Git
import GitHub
import Sugar

public struct Output: Codable {
	public struct PullRequest: Codable {
		public var title: String
		public var headBranch: String
		public var baseBranch: String
		public var body: String?
		public var assignees: [String]
		public var labels: [Label]
		public var milestone: Milestone?
		public var isDraft: Bool
	}

	public struct AnalyticsData: Codable {
		public var info: [String: AnyCodable]
	}

	public var pullRequest: PullRequest
	public var analyticsData: AnalyticsData
}

extension Output: CustomStringConvertible {
	public var description: String {
		let indentation: (Int) -> String = { String(repeating: " ", count: $0) }

		let assignees = !pullRequest.assignees.isEmpty ? "\n" + pullRequest.assignees.map { indentation(6) + $0 }.joined(separator: "\n") : "<none>"
		let labels = !pullRequest.labels.isEmpty ? "\n" + pullRequest.labels.map { indentation(6) + $0.name }.joined(separator: "\n") : "<none>"

		let pullRequestDescription = """
		Pull request:
		   title: \(pullRequest.title)
		   headBranch: \(pullRequest.headBranch)
		   baseBranch: \(pullRequest.baseBranch)
		   body: \(pullRequest.body ?? "<none>")
		   assignees: \(assignees)
		   labels: \(labels)
		   milestone: \(pullRequest.milestone?.title ?? "<none>")
		   isDraft: \(pullRequest.isDraft)
		"""

		guard !analyticsData.info.isEmpty else {
			return pullRequestDescription
		}

		let analyticsDataInfo = analyticsData.info
			.map { indentation(3) + "\($0): \($1)" }
			.joined(separator: "\n")

		return pullRequestDescription + "\n\n" + """
		Analytics data:
		\(analyticsDataInfo)
		"""
	}
}

extension Output {
	public static func path(for repository: Repository) -> URL {
		let repositoryPathSha1 = repository.topLevelPath.path.sha1()
		return FileManager.default.temporaryDirectory.appendingPathComponent("badonde-output-\(repositoryPathSha1).json")
	}
}

extension Output {
	func write(to url: URL) throws {
		let outputData = try JSONEncoder().encode(self)
		try outputData.write(to: url)
	}
}

var output: Output!

public func title(_ title: String) {
	output.pullRequest.title = title
}

public func body(_ body: String) {
	output.pullRequest.body = body
}

public func assignee(_ assignee: String) {
	output.pullRequest.assignees.append(assignee)
}

public func label(_ label: Label) {
	output.pullRequest.labels.append(label)
}

public func milestone(_ milestone: Milestone) {
	output.pullRequest.milestone = milestone
}

public func draft(_ isDraft: Bool) {
	output.pullRequest.isDraft = isDraft
}

public func analytics<T: Codable>(key: String, value: T) {
	output.analyticsData.info[key] = AnyCodable(value)
}

public func analytics<T: Codable>(pullRequestClosure: (Output.PullRequest) -> [String: T]) {
	let info = pullRequestClosure(output.pullRequest).mapValues { AnyCodable($0) }
	output.analyticsData.info.merge(info, uniquingKeysWith: { _, new in new })
}
