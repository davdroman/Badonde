import XCTest
@testable import GitHub

final class RepositoryShorthandTests: XCTestCase {
	func testRepositoryShorthand_initWithRawValue_validUsername_validRepository() {
		let shorthand = Repository.Shorthand(rawValue: "user-123/repo-123")
		XCTAssertNotNil(shorthand)
	}

	func testRepositoryShorthand_initWithRawValue_invalidUsername_invalidRepository() {
		let shorthand = Repository.Shorthand(rawValue: "user_123/repo_123")
		XCTAssertNil(shorthand)
	}

	func testRepositoryShorthand_initWithRawValue_minLengthUsername_minLengthRepository() {
		let shorthand = Repository.Shorthand(rawValue: "a/b")
		XCTAssertNotNil(shorthand)
	}

	func testRepositoryShorthand_initWithRawValue_maxLengthUsername_maxLengthRepository() {
		let longUsername = String(repeating: "a", count: 39)
		let longRepository = String(repeating: "b", count: 39)
		let shorthand = Repository.Shorthand(rawValue: "\(longUsername)/\(longRepository)")
		XCTAssertNotNil(shorthand)
	}

	func testRepositoryShorthand_initWithRawValue_validUsername_underMinLengthRepository() {
		let shorthand = Repository.Shorthand(rawValue: "/repo-123")
		XCTAssertNil(shorthand)
	}

	func testRepositoryShorthand_initWithRawValue_underMinLengthUsername_validRepository() {
		let shorthand = Repository.Shorthand(rawValue: "user-123/")
		XCTAssertNil(shorthand)
	}

	func testRepositoryShorthand_initWithRawValue_overMaxLengthUsername_overMaxLengthRepository() {
		let longUsername = String(repeating: "a", count: 40)
		let longRepository = String(repeating: "b", count: 40)
		let shorthand = Repository.Shorthand(rawValue: "\(longUsername)/\(longRepository)")
		XCTAssertNil(shorthand)
	}
}
