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
		public var reviewers: [String]
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

		let body = pullRequest.body.map { "\n" + $0.components(separatedBy: .newlines).map { indentation(6) + $0 }.joined(separator: "\n") }
		let reviewers = !pullRequest.reviewers.isEmpty ? "\n" + pullRequest.reviewers.map { indentation(6) + $0 }.joined(separator: "\n") : "<none>"
		let assignees = !pullRequest.assignees.isEmpty ? "\n" + pullRequest.assignees.map { indentation(6) + $0 }.joined(separator: "\n") : "<none>"
		let labels = !pullRequest.labels.isEmpty ? "\n" + pullRequest.labels.map { indentation(6) + $0.name }.joined(separator: "\n") : "<none>"

		let pullRequestDescription = """
		Pull request:
		   title: \(pullRequest.title)
		   headBranch: \(pullRequest.headBranch)
		   baseBranch: \(pullRequest.baseBranch)
		   body: \(body ?? "<none>")
		   reviewers: \(reviewers)
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

public func reviewer(_ reviewer: User) {
	BadondeKit.reviewer(reviewer.login)
}

public func reviewer(_ name: String) {
	output.pullRequest.reviewers.append(name)
}

public func assignee(_ assignee: User) {
	BadondeKit.assignee(assignee.login)
}

public func assignee(_ name: String) {
	output.pullRequest.assignees.append(name)
}

public func label(_ label: Label) {
	output.pullRequest.labels.append(label)
}

public func label(where labelMatcher: (Label) -> Bool) {
	guard let label = badonde.github.labels.first(where: labelMatcher) else {
		return
	}
	BadondeKit.label(label)
}

public func label(named name: String) {
	label(where: { $0.name == name })
}

public func label(roughlyNamed name: String) {
	label(where: { $0.name ~= name })
}

public func milestone(_ milestone: Milestone) {
	output.pullRequest.milestone = milestone
}

public func milestone(where milestoneMatcher: (Milestone) -> Bool) {
	guard let milestone = badonde.github.milestones.first(where: milestoneMatcher) else {
		return
	}
	BadondeKit.milestone(milestone)
}

public func milestone(named name: String) {
	milestone(where: { $0.title == name })
}

public func milestone(roughlyNamed name: String) {
	milestone(where: { $0.title ~= name })
}

public func draft(_ isDraft: Bool) {
	output.pullRequest.isDraft = isDraft
}

public func analytics<T>(_ dictionary: [String: T]) {
	let info = dictionary.mapValues { AnyCodable($0) }
	output.analyticsData.info.merge(info, uniquingKeysWith: { _, new in new })
}
