import XCTest
@testable import Git
import TestSugar

final class RepositoryInteractorMock: RepositoryInteractor {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "txt" }

		case repository
	}

	func getTopLevelPath(from path: String) throws -> String {
		return try Fixture.repository.load(as: String.self)
	}
}

final class RepositoryTests: XCTestCase {
	func testInit() throws {
		let interactor = RepositoryInteractorMock()
		let repository = try Repository(path: URL(fileURLWithPath: "/Users/user/projects/repo/Sources/ModuleA"), interactor: interactor)

		XCTAssertEqual(repository.topLevelPath.path, "/Users/user/projects/repo")
	}
}
