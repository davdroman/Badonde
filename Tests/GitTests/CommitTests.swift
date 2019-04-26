import XCTest
@testable import Git
import TestSugar

final class CommitInteractorMock: CommitInteractor {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "txt" }

		case commitCountZero = "commit_count_zero"
		case commitCountSingle = "commit_count_single"
		case commitCountMultiple = "commit_count_multiple"
	}

	var returnCommitCountZero = false
	var multipleCommitCountFixture: FixtureLoadable?

	func count(baseBranches: [String], targetBranch: String, after date: Date?) throws -> String {
		guard !returnCommitCountZero else {
			return try Fixture.commitCountZero.load(as: String.self)
		}

		switch baseBranches.count {
		case 0:
			return ""
		case 1:
			return try Fixture.commitCountSingle.load(as: String.self)
		default:
			let fixture = multipleCommitCountFixture ?? Fixture.commitCountMultiple
			return try fixture.load(as: String.self)
		}
	}
}

final class CommitTests: XCTestCase {
	func testCount_none() throws {
		let interactor = CommitInteractorMock()
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let targetBranch = try Branch(name: "target-branch", source: .remote(remote))

		XCTAssertThrowsError(try Commit.count(baseBranches: [], targetBranch: targetBranch, after: nil, interactor: interactor)) { error in
			switch error {
			case Commit.Error.numberNotFound:
				break
			default:
				XCTFail("Commit.count threw the wrong error")
			}
		}
	}

	func testCount_single() throws {
		let interactor = CommitInteractorMock()
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let baseBranch = try Branch(name: "base-branch", source: .remote(remote))
		let targetBranch = try Branch(name: "target-branch", source: .remote(remote))
		let count = try Commit.count(baseBranch: baseBranch, targetBranch: targetBranch, after: nil, interactor: interactor)

		XCTAssertEqual(count, 7)
	}

	func testCount_multiple() throws {
		let interactor = CommitInteractorMock()
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let baseBranches = [
			try Branch(name: "base-branch-a", source: .remote(remote)),
			try Branch(name: "base-branch-b", source: .remote(remote)),
			try Branch(name: "base-branch-c", source: .remote(remote))
		]
		let targetBranch = try Branch(name: "target-branch", source: .remote(remote))
		let counts = try Commit.count(baseBranches: baseBranches, targetBranch: targetBranch, after: nil, interactor: interactor)

		let (branchA, countA) = counts[0]
		XCTAssertEqual(branchA, baseBranches[0])
		XCTAssertEqual(countA, 8)

		let (branchB, countB) = counts[1]
		XCTAssertEqual(branchB, baseBranches[1])
		XCTAssertEqual(countB, 133)

		let (branchC, countC) = counts[2]
		XCTAssertEqual(branchC, baseBranches[2])
		XCTAssertEqual(countC, 543)
	}
}
