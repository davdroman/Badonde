import XCTest
@testable import Git
import TestSugar

final class BranchInteractorMock: BranchInteractor {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "txt" }

		case currentBranch = "current_branch"

		case allLocalBranches = "all_local_branches"
		case allOriginRemoteBranches = "all_origin_remote_branches"
		case allSshOriginRemoteBranches = "all_ssh_origin_remote_branches"
	}

	func getCurrentBranch() throws -> String {
		return try Fixture.currentBranch.load(as: String.self)
	}

	func getAllBranches(from source: Branch.Source) throws -> String {
		switch source {
		case .local:
			return try Fixture.allLocalBranches.load(as: String.self)
		case .remote(let remote):
			return try Fixture(rawValue: "all_\(remote.name)_remote_branches")!.load(as: String.self)
		}
	}
}

extension BranchTests {
	enum Constant {
		static let originRemoteSource = Branch.Source.remote(Remote(name: "origin", url: URL(string: "https://github.com/user/repo.git")!))
		static let sshOriginRemoteSource = Branch.Source.remote(Remote(name: "ssh_origin", url: URL(string: "git@github.com:user/repo.git")!))
	}
}

final class BranchTests: XCTestCase {
	func testBranchInit_withLocalSource_normalName() throws {
		let branch = try Branch(name: "my-branch", source: .local)
		XCTAssertEqual(branch.name, "my-branch")
		XCTAssertEqual(branch.source, .local)
		XCTAssertEqual(branch.fullName, "my-branch")
	}

	func testBranchInit_withLocalSource_invalidName() throws {
		XCTAssertThrowsError(try Branch(name: "my branch", source: .local)) { error in
			switch error {
			case Branch.Error.nameContainsInvalidCharacters:
				break
			default:
				XCTFail("Branch initializer threw the wrong error")
			}
		}
	}

	func testBranchInit_withLocalSource_remoteName() throws {
		let branchA = try Branch(name: "origin/my-branch", source: .local)
		XCTAssertEqual(branchA.name, "origin/my-branch")
		XCTAssertEqual(branchA.source, .local)
		XCTAssertEqual(branchA.fullName, "origin/my-branch")

		let branchB = try Branch(name: "remotes/origin/my-branch", source: .local)
		XCTAssertEqual(branchB.name, "remotes/origin/my-branch")
		XCTAssertEqual(branchB.source, .local)
		XCTAssertEqual(branchB.fullName, "remotes/origin/my-branch")

		let branchC = try Branch(name: "refs/remotes/origin/my-branch", source: .local)
		XCTAssertEqual(branchC.name, "refs/remotes/origin/my-branch")
		XCTAssertEqual(branchC.source, .local)
		XCTAssertEqual(branchC.fullName, "refs/remotes/origin/my-branch")
	}

	func testBranchInit_withRemoteSource_normalName() throws {
		let branch = try Branch(name: "my-branch", source: Constant.originRemoteSource)
		XCTAssertEqual(branch.name, "my-branch")
		XCTAssertEqual(branch.source, Constant.originRemoteSource)
		XCTAssertEqual(branch.fullName, "origin/my-branch")
	}

	func testBranchInit_withRemoteSource_remoteName() throws {
		let branchA = try Branch(name: "origin/my-branch", source: Constant.originRemoteSource)
		XCTAssertEqual(branchA.name, "my-branch")
		XCTAssertEqual(branchA.source, Constant.originRemoteSource)
		XCTAssertEqual(branchA.fullName, "origin/my-branch")

		let branchB = try Branch(name: "remotes/origin/my-branch", source: Constant.originRemoteSource)
		XCTAssertEqual(branchB.name, "my-branch")
		XCTAssertEqual(branchB.source, Constant.originRemoteSource)
		XCTAssertEqual(branchB.fullName, "origin/my-branch")

		let branchC = try Branch(name: "refs/remotes/origin/my-branch", source: Constant.originRemoteSource)
		XCTAssertEqual(branchC.name, "my-branch")
		XCTAssertEqual(branchC.source, Constant.originRemoteSource)
		XCTAssertEqual(branchC.fullName, "origin/my-branch")
	}
}

extension BranchTests {
	func testBranchGetCurrent() throws {
		let interactor = BranchInteractorMock()
		let currentBranch = try Branch.current(interactor: interactor)

		XCTAssertEqual(currentBranch.name, "standalone-git-module")
	}
}

extension BranchTests {
	func testBranchGetAll_Local() throws {
		let interactor = BranchInteractorMock()
		let allBranches = try Branch.getAll(from: .local, interactor: interactor)

		XCTAssertEqual(allBranches.count, 4)

		let branchA = allBranches.first
		let branchB = allBranches.dropFirst().first
		let branchC = allBranches.dropFirst(2).first
		let branchD = allBranches.dropFirst(3).first

		XCTAssertEqual(branchA?.name, "develop")
		XCTAssertEqual(branchA?.source, .local)

		XCTAssertEqual(branchB?.name, "master")
		XCTAssertEqual(branchB?.source, .local)

		XCTAssertEqual(branchC?.name, "standalone-git-module")
		XCTAssertEqual(branchC?.source, .local)

		XCTAssertEqual(branchD?.name, "swift-5")
		XCTAssertEqual(branchD?.source, .local)
	}

	func testBranchGetAll_OriginRemote() throws {
		let interactor = BranchInteractorMock()
		let allBranches = try Branch.getAll(from: Constant.originRemoteSource, interactor: interactor)

		XCTAssertEqual(allBranches.count, 4)

		let branchA = allBranches.first
		let branchB = allBranches.dropFirst().first
		let branchC = allBranches.dropFirst(2).first
		let branchD = allBranches.dropFirst(3).first

		XCTAssertEqual(branchA?.name, "develop")
		XCTAssertEqual(branchA?.source, Constant.originRemoteSource)

		XCTAssertEqual(branchB?.name, "master")
		XCTAssertEqual(branchB?.source, Constant.originRemoteSource)

		XCTAssertEqual(branchC?.name, "standalone-git-module")
		XCTAssertEqual(branchC?.source, Constant.originRemoteSource)

		XCTAssertEqual(branchD?.name, "swift-5")
		XCTAssertEqual(branchD?.source, Constant.originRemoteSource)
	}

	func testBranchGetAll_SshOriginRemote() throws {
		let interactor = BranchInteractorMock()
		let allBranches = try Branch.getAll(from: Constant.sshOriginRemoteSource, interactor: interactor)

		XCTAssertEqual(allBranches.count, 4)

		let branchA = allBranches.first
		let branchB = allBranches.dropFirst().first
		let branchC = allBranches.dropFirst(2).first
		let branchD = allBranches.dropFirst(3).first

		XCTAssertEqual(branchA?.name, "develop")
		XCTAssertEqual(branchA?.source, Constant.sshOriginRemoteSource)

		XCTAssertEqual(branchB?.name, "master")
		XCTAssertEqual(branchB?.source, Constant.sshOriginRemoteSource)

		XCTAssertEqual(branchC?.name, "standalone-git-module")
		XCTAssertEqual(branchC?.source, Constant.sshOriginRemoteSource)

		XCTAssertEqual(branchD?.name, "swift-5")
		XCTAssertEqual(branchD?.source, Constant.sshOriginRemoteSource)
	}
}

extension BranchTests {
	func testBranchIsAheadOfRemote() throws {
		let interactor = CommitInteractorMock()
		let branch = try Branch(name: "develop", source: .local)
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let isAhead = try branch.isAhead(of: remote, interactor: interactor)

		XCTAssertTrue(isAhead)
	}

	func testBranchIsNotAheadOfRemote() throws {
		let interactor = CommitInteractorMock()
		interactor.returnCommitCountZero = true
		let branch = try Branch(name: "develop", source: .local)
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let isAhead = try branch.isAhead(of: remote, interactor: interactor)

		XCTAssertFalse(isAhead)
	}
}

extension BranchTests {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "txt" }

		case commitCountMultiple = "commit_count_multiple"
		case commitCountMultipleEqual = "commit_count_multiple_equal"
	}

	func testBranchParent() throws {
		let branchInteractor = BranchInteractorMock()
		let commitInteractor = CommitInteractorMock()
		commitInteractor.multipleCommitCountFixture = Fixture.commitCountMultiple
		let remoteInteractor = RemoteInteractorMock()

		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let branch = try Branch(name: "target-branch", source: .local)
		let parentBranch = try branch.parent(
			for: remote,
			branchInteractor: branchInteractor,
			commitInteractor: commitInteractor,
			remoteInteractor: remoteInteractor
		)

		XCTAssertEqual(parentBranch.name, "swift-5")
		XCTAssertEqual(parentBranch.source, .remote(remote))
	}

	func testBranchParent_fallsBackToDefaultBranch() throws {
		let branchInteractor = BranchInteractorMock()
		let commitInteractor = CommitInteractorMock()
		commitInteractor.multipleCommitCountFixture = Fixture.commitCountMultipleEqual
		let remoteInteractor = RemoteInteractorMock()

		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let branch = try Branch(name: "target-branch", source: .local)
		let parentBranch = try branch.parent(
			for: remote,
			branchInteractor: branchInteractor,
			commitInteractor: commitInteractor,
			remoteInteractor: remoteInteractor
		)

		XCTAssertEqual(parentBranch.name, "develop")
		XCTAssertEqual(parentBranch.source, .remote(remote))
	}
}
