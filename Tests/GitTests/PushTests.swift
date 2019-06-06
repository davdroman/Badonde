import XCTest
@testable import Git
import TestSugar

final class PushInteractorSpy: PushInteractor {
	typealias RemoteAndBranch = (remote: String, branch: String)

	let performSpy: ((RemoteAndBranch) -> Void)

	init(performSpy: @escaping ((RemoteAndBranch) -> Void)) {
		self.performSpy = performSpy
	}

	func perform(remote: String, branch: String) throws {
		performSpy((remote: remote, branch: branch))
	}
}

final class PushTests: XCTestCase {
	func testPerform_LocalBranch() throws {
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let branch = try Branch(name: "develop", source: .local)

		Push.interactor = PushInteractorSpy {
			XCTAssertEqual($0.remote, "origin")
			XCTAssertEqual($0.branch, "develop")
		}

		try Push.perform(remote: remote, branch: branch)
	}

	func testPerform_RemoteBranch() throws {
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let branch = try Branch(name: "develop", source: .remote(remote))

		Push.interactor = PushInteractorSpy {
			XCTAssertEqual($0.remote, "origin")
			XCTAssertEqual($0.branch, "develop")
		}

		try Push.perform(remote: remote, branch: branch)
	}
}
