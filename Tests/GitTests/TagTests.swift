import XCTest
@testable import Git
import TestSugar

final class TagInteractorMock: TagInteractor {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "txt" }

		case tags
	}

	func getAllTags(atPath path: String) throws -> String {
		return try Fixture.tags.load(as: String.self)
	}
}

final class TagTests: XCTestCase {
	func testInit() throws {
		Tag.interactor = TagInteractorMock()

		let tags = try Tag.getAll(atPath: "")
		let expectedTags = [
			"2.0.1.1",
			"2.0.1",
			"2.0.0",
			"2.0.0-beta.10",
		].map(Tag.init(name:))
		XCTAssertEqual(tags, expectedTags)
	}
}
