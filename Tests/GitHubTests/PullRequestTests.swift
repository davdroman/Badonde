import XCTest
@testable import GitHub

final class PullRequestTests: XCTestCase {
	func testFactory_urlIsValid_withBaseBranch_withTargetBranch() {
		XCTAssertEqual(try pullRequest().url().absoluteString, "https://github.com/user/repo/compare/base...target")
	}

	func testFactory_urlIsValid_withBranches_withTitle() {
		let pullRequest = self.pullRequest(title: "Title of the PR 100% correctly encoded with extra emoji sauce! 🍗🥗💪🏃‍♂️")
		XCTAssertEqual(try pullRequest.url().absoluteString, "https://github.com/user/repo/compare/base...target?title=Title%20of%20the%20PR%20100%25%20correctly%20encoded%20with%20extra%20emoji%20sauce!%20%F0%9F%8D%97%F0%9F%A5%97%F0%9F%92%AA%F0%9F%8F%83%E2%80%8D%E2%99%82%EF%B8%8F")
	}

	func testFactory_urlIsValid_withBranches_withOneLabel() {
		let pullRequest = self.pullRequest(labels: ["Label 1"])
		XCTAssertEqual(try pullRequest.url().absoluteString, "https://github.com/user/repo/compare/base...target?labels=Label%201")
	}

	func testFactory_urlIsValid_withBranches_withMultipleLabels() {
		let pullRequest = self.pullRequest(labels: ["Label 1", "Label 2", "Label 3"])
		XCTAssertEqual(try pullRequest.url().absoluteString, "https://github.com/user/repo/compare/base...target?labels=Label%201,Label%202,Label%203")
	}

	func testFactory_urlIsValid_withBranches_withMilestone() {
		let pullRequest = self.pullRequest(milestone: "RT ∞")
		XCTAssertEqual(try pullRequest.url().absoluteString, "https://github.com/user/repo/compare/base...target?milestone=RT%20%E2%88%9E")
	}
}

extension PullRequestTests {
	enum Constant {
		static let repositoryShorthand = "user/repo"
		static let baseBranch = "base"
		static let targetBranch = "target"
	}

	func pullRequest(title: String = "", labels: [String] = [], milestone: String? = nil) -> PullRequest {
		return PullRequest.init(
			repositoryShorthand: Constant.repositoryShorthand,
			baseBranch: Constant.baseBranch,
			targetBranch: Constant.targetBranch,
			title: title,
			labels: labels,
			milestone: milestone
		)
	}
}
