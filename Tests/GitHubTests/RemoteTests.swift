import XCTest
@testable import GitHub
import Git
import TestSugar

final class RemoteInteractorMock: GitHub.RemoteInteractor {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "txt" }

		case repositoryShorthand = "repository_shorthand"
	}

	func repositoryShorthand(forRemote remote: String) throws -> String {
		return try Fixture.repositoryShorthand.load(as: String.self)
	}
}

final class RemoteTests: XCTestCase {
	func testRepositoryShorthand() throws {
		let interactor = RemoteInteractorMock()
		let remote = Remote(name: "origin", url: URL(string: "git@github.com:user/repo.git")!)
		let shorthand = try remote.repositoryShorthand(interactor: interactor)

		XCTAssertEqual(shorthand.username, "user")
		XCTAssertEqual(shorthand.repository, "repo")
	}
}
