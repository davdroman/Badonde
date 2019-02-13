import XCTest
@testable import BadondeCore

final class PullRequestURLFactoryTests: XCTestCase {
	func testFactory_urlIsValid_withRepositoryShorthandOnly() {
		let factory = PullRequestURLFactory(repositoryShorthand: "user/repo")
		XCTAssertEqual(factory.url?.absoluteString, "https://github.com/user/repo/compare/")
	}

	func testFactory_urlIsValid_withBaseBranch_withTargetBranch() {
		let factory = PullRequestURLFactory(repositoryShorthand: "user/repo")
		factory.baseBranch = "base"
		factory.targetBranch = "target"
		XCTAssertEqual(factory.url?.absoluteString, "https://github.com/user/repo/compare/base...target")
	}

	func testFactory_urlIsValid_withoutBaseBranch_withTargetBranch() {
		let factory = PullRequestURLFactory(repositoryShorthand: "user/repo")
		factory.baseBranch = nil
		factory.targetBranch = "target"
		XCTAssertEqual(factory.url?.absoluteString, "https://github.com/user/repo/compare/target")
	}

	func testFactory_urlIsValid_withBaseBranch_withoutTargetBranch() {
		let factory = PullRequestURLFactory(repositoryShorthand: "user/repo")
		factory.baseBranch = "base"
		factory.targetBranch = nil
		XCTAssertEqual(factory.url?.absoluteString, "https://github.com/user/repo/compare/base...")
	}

	func testFactory_urlIsValid_withoutBaseBranch_withoutTargetBranch() {
		let factory = PullRequestURLFactory(repositoryShorthand: "user/repo")
		factory.baseBranch = nil
		factory.targetBranch = nil
		XCTAssertEqual(factory.url?.absoluteString, "https://github.com/user/repo/compare/")
	}

	func testFactory_urlIsValid_withBranches_withTitle() {
		let factory = PullRequestURLFactory(repositoryShorthand: "user/repo")
		factory.baseBranch = "base"
		factory.targetBranch = "target"
		factory.title = "Title of the PR 100% correctly encoded with extra emoji sauce! 🍗🥗💪🏃‍♂️"
		XCTAssertEqual(factory.url?.absoluteString, "https://github.com/user/repo/compare/base...target?title=Title%20of%20the%20PR%20100%25%20correctly%20encoded%20with%20extra%20emoji%20sauce!%20%F0%9F%8D%97%F0%9F%A5%97%F0%9F%92%AA%F0%9F%8F%83%E2%80%8D%E2%99%82%EF%B8%8F")
	}

	func testFactory_urlIsValid_withBranches_withZeroLabels() {
		let factory = PullRequestURLFactory(repositoryShorthand: "user/repo")
		factory.baseBranch = "base"
		factory.targetBranch = "target"
		factory.labels = []
		XCTAssertEqual(factory.url?.absoluteString, "https://github.com/user/repo/compare/base...target?labels=")
	}

	func testFactory_urlIsValid_withBranches_withOneLabel() {
		let factory = PullRequestURLFactory(repositoryShorthand: "user/repo")
		factory.baseBranch = "base"
		factory.targetBranch = "target"
		factory.labels = ["Label 1"]
		XCTAssertEqual(factory.url?.absoluteString, "https://github.com/user/repo/compare/base...target?labels=Label%201")
	}

	func testFactory_urlIsValid_withBranches_withMultipleLabels() {
		let factory = PullRequestURLFactory(repositoryShorthand: "user/repo")
		factory.baseBranch = "base"
		factory.targetBranch = "target"
		factory.labels = ["Label 1", "Label 2", "Label 3"]
		XCTAssertEqual(factory.url?.absoluteString, "https://github.com/user/repo/compare/base...target?labels=Label%201,Label%202,Label%203")
	}

	func testFactory_urlIsValid_withBranches_withMilestone() {
		let factory = PullRequestURLFactory(repositoryShorthand: "user/repo")
		factory.baseBranch = "base"
		factory.targetBranch = "target"
		factory.milestone = "RT ∞"
		XCTAssertEqual(factory.url?.absoluteString, "https://github.com/user/repo/compare/base...target?milestone=RT%20%E2%88%9E")
	}
}
