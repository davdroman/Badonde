import XCTest
@testable import Git
import TestSugar

final class RemoteInteractorMock: RemoteInteractor {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "txt" }

		case allRemotes = "all_remotes"
		case originRemoteURL = "origin_url"
		case sshOriginRemoteURL = "ssh_origin_url"
		case originDefaultBranch = "origin_default_branch"
	}

	func getAllRemotes() throws -> String {
		return try Fixture.allRemotes.load(as: String.self)
	}

	func getURL(forRemote remote: String) throws -> String {
		return try Fixture(rawValue: remote + "_url")!.load(as: String.self)
	}

	func defaultBranch(forRemote remote: String) throws -> String {
		return try Fixture.originDefaultBranch.load(as: String.self)
	}
}

final class RemoteTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Remote.interactor = RemoteInteractorMock()
	}

	func testInit() {
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		XCTAssertEqual(remote.name, "origin")
		XCTAssertEqual(remote.url.absoluteString, "git@github.com:user/repo.git")
	}
}

extension RemoteTests {
	func testRemoteGetAll() throws {
		let allRemotes = try Remote.getAll()

		let remoteA = allRemotes.first
		let remoteB = allRemotes.dropFirst().first

		XCTAssertEqual(remoteA?.name, "origin")
		XCTAssertEqual(remoteA?.url.absoluteString, "https://github.com/user/repo.git")

		XCTAssertEqual(remoteB?.name, "ssh_origin")
		XCTAssertEqual(remoteB?.url.absoluteString, "git@github.com:user/repo.git")
	}
}

extension RemoteTests {
	func testRemoteDefaultBranch() throws {
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let defaultBranch = try remote.defaultBranch()
		let expectedDefaultBranch = try Branch(name: "develop", source: .remote(remote))

		XCTAssertEqual(defaultBranch, expectedDefaultBranch)
	}
}
