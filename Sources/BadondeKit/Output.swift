import Foundation
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
	public static func path(forRepositoryPath path: String) -> String {
		return FileManager.default.temporaryDirectory.appendingPathComponent("badonde-output-\(path.sha1()).json").path
	}
}

extension Output {
	func write(to url: URL) throws {
		let outputData = try JSONEncoder().encode(self)
		try outputData.write(to: url)
	}
}

var output: Output!

/// Sets the title of the PR.
public func title(_ title: String) {
	output.pullRequest.title = title
}

/// Sets the body of the PR.
public func body(_ body: String) {
	output.pullRequest.body = body
}

/// Adds a reviewer to the PR.
public func reviewer(_ reviewer: User) {
	BadondeKit.reviewer(reviewer.login)
}

/// Adds a reviewer by login handle to the PR.
public func reviewer(_ login: String) {
	output.pullRequest.reviewers.append(login)
}

/// Adds an assignee to the PR.
public func assignee(_ assignee: User) {
	BadondeKit.assignee(assignee.login)
}

/// Adds an assignee by login handle to the PR.
public func assignee(_ login: String) {
	output.pullRequest.assignees.append(login)
}

/// Adds a label to the PR.
public func label(_ label: Label) {
	output.pullRequest.labels.append(label)
}

/// Adds a label that matches the specified predicate to the PR.
public func label(where labelMatcher: (Label) -> Bool) {
	guard let label = badonde.github.labels.first(where: labelMatcher) else {
		return
	}
	BadondeKit.label(label)
}

/// Adds a label, by name, to the PR.
public func label(named name: String) {
	label(where: { $0.name == name })
}

/// Adds a label, roughly matching the specified name, to the PR.
public func label(roughlyNamed name: String) {
	label(where: { $0.name ~= name })
}

/// Sets the milestone of the PR.
public func milestone(_ milestone: Milestone) {
	output.pullRequest.milestone = milestone
}

/// Sets the milestone, matching the specified predicate, for the PR.
public func milestone(where milestoneMatcher: (Milestone) -> Bool) {
	guard let milestone = badonde.github.milestones.first(where: milestoneMatcher) else {
		return
	}
	BadondeKit.milestone(milestone)
}

/// Sets the milestone, by name, for the PR.
public func milestone(named name: String) {
	milestone(where: { $0.title == name })
}

/// Sets the milestone, roughly matching the specified name, for the PR.
public func milestone(roughlyNamed name: String) {
	milestone(where: { $0.title ~= name })
}

/// Sets the draft status for the PR.
public func draft(_ isDraft: Bool) {
	output.pullRequest.isDraft = isDraft
}

/// Specifies analytics data to be reported after the PR is created.
public func analytics<T>(_ dictionary: [String: T]) {
	let info = dictionary.mapValues { AnyCodable($0) }
	output.analyticsData.info.merge(info, uniquingKeysWith: { _, new in new })
}
