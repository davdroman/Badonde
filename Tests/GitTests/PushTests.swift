import XCTest
@testable import Git
import TestSugar

final class PushInteractorSpy: PushInteractor {
	typealias RemoteAndBranch = (remote: String, branch: String)
	var performSpy: ((RemoteAndBranch) -> Void)?

	func perform(remote: String, branch: String) throws {
		performSpy?((remote: remote, branch: branch))
	}
}

final class PushTests: XCTestCase {
	func testPerform_LocalBranch() throws {
		let interactor = PushInteractorSpy()
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let branch = try Branch(name: "develop", source: .local)

		interactor.performSpy = {
			XCTAssertEqual($0.remote, "origin")
			XCTAssertEqual($0.branch, "develop")
		}
		try Push.perform(remote: remote, branch: branch, interactor: interactor)
	}

	func testPerform_RemoteBranch() throws {
		let interactor = PushInteractorSpy()
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let branch = try Branch(name: "develop", source: .remote(remote))

		interactor.performSpy = {
			XCTAssertEqual($0.remote, "origin")
			XCTAssertEqual($0.branch, "develop")
		}
		try Push.perform(remote: remote, branch: branch, interactor: interactor)
	}
}
