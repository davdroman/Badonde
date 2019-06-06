import XCTest
@testable import Git
import TestSugar

final class RepositoryInteractorMock: RepositoryInteractor {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "txt" }

		case repository
	}

	func getTopLevelPath(forPath path: String) throws -> String {
		return try Fixture.repository.load(as: String.self)
	}
}

final class RepositoryTests: XCTestCase {
	func testInit() throws {
		Repository.interactor = RepositoryInteractorMock()

		let repository = try Repository(atPath: "/Users/user/projects/repo/Sources/ModuleA")
		XCTAssertEqual(repository.topLevelPath, "/Users/user/projects/repo")
	}
}
