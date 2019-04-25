import XCTest
@testable import Git
import TestSugar

final class CommitTests: XCTestCase {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "txt" }

		case commit
	}

	func testInit() throws {
		let commit = try Commit(rawCommitContent: Fixture.commit.load(as: String.self))

		XCTAssertEqual(commit.hash, "4dbb765e835823d2d8842f8e9a1f62eb5999ccab")
		XCTAssertEqual(commit.author.name, "davdroman")
		XCTAssertEqual(commit.author.email, "d@vidroman.me")
		XCTAssertEqual(commit.date.timeIntervalSince1970, 1556186505)
		XCTAssertEqual(commit.subject, "Fix `make` installation command in README")
		XCTAssertEqual(commit.body, "")
	}
}
