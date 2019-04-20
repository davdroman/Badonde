import XCTest
@testable import Git
import TestSugar

final class RemoteInteractorMock: RemoteInteractor {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "txt" }

		case allRemotes = "all_remotes"
		case originRemote = "origin_url"
		case sshOriginRemote = "ssh_origin_url"
	}

	func getAllRemotes() throws -> String {
		return try Fixture.allRemotes.load(as: String.self)
	}

	func getURL(forRemote remote: String) throws -> String {
		return try Fixture(rawValue: remote + "_url")!.load(as: String.self)
	}
}

final class RemoteTests: XCTestCase {
	func testInit() {
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		XCTAssertEqual(remote.name, "origin")
		XCTAssertEqual(remote.url.absoluteString, "git@github.com:user/repo.git")
	}
}

extension RemoteTests {
	func testRemoteGetAll() throws {
		let interactor = RemoteInteractorMock()
		let allRemotes = try Remote.getAll(interactor: interactor)

		let remoteA = allRemotes.first
		let remoteB = allRemotes.dropFirst().first
		XCTAssertEqual(remoteA?.name, "origin")
		XCTAssertEqual(remoteA?.url.absoluteString, "https://github.com/user/repo.git")
		XCTAssertEqual(remoteB?.name, "ssh_origin")
		XCTAssertEqual(remoteB?.url.absoluteString, "git@github.com:user/repo.git")
	}
}
