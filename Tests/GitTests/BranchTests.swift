import XCTest
@testable import Git

final class BranchTests: XCTestCase {
	func testBranchInit_withLocalSource_normalName() {
		let branch = Branch(name: "my-branch", source: .local)
		XCTAssertEqual(branch.name, "my-branch")
		XCTAssertEqual(branch.source, .local)
		XCTAssertEqual(branch.fullName, "my-branch")
	}

	func testBranchInit_withLocalSource_remoteName() {
		let branchA = Branch(name: "origin/my-branch", source: .local)
		XCTAssertEqual(branchA.name, "origin/my-branch")
		XCTAssertEqual(branchA.source, .local)
		XCTAssertEqual(branchA.fullName, "origin/my-branch")

		let branchB = Branch(name: "remotes/origin/my-branch", source: .local)
		XCTAssertEqual(branchB.name, "remotes/origin/my-branch")
		XCTAssertEqual(branchB.source, .local)
		XCTAssertEqual(branchB.fullName, "remotes/origin/my-branch")
	}

	func testBranchInit_withRemoteSource_normalName() {
		let branch = Branch(name: "my-branch", source: Constant.remoteSource)
		XCTAssertEqual(branch.name, "my-branch")
		XCTAssertEqual(branch.source, Constant.remoteSource)
		XCTAssertEqual(branch.fullName, "origin/my-branch")
	}

	func testBranchInit_withRemoteSource_remoteName() {
		let branchA = Branch(name: "origin/my-branch", source: Constant.remoteSource)
		XCTAssertEqual(branchA.name, "my-branch")
		XCTAssertEqual(branchA.source, Constant.remoteSource)
		XCTAssertEqual(branchA.fullName, "origin/my-branch")

		let branchB = Branch(name: "remotes/origin/my-branch", source: Constant.remoteSource)
		XCTAssertEqual(branchB.name, "my-branch")
		XCTAssertEqual(branchB.source, Constant.remoteSource)
		XCTAssertEqual(branchB.fullName, "origin/my-branch")
	}
}

private extension BranchTests {
	enum Constant {
		static let remoteSource = Branch.Source.remote(Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!))
	}
}
