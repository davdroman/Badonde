import XCTest
@testable import Configuration

final class KeyPathTests: XCTestCase {
	// MARK: Init

	func testKeyPathInit_withEmptyPath() {
		let keypath = Configuration.KeyPath(rawValue: "")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withDot() {
		let keypath = Configuration.KeyPath(rawValue: ".")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withTwoDots() {
		let keypath = Configuration.KeyPath(rawValue: "..")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withMultipleDots() {
		let keypath = Configuration.KeyPath(rawValue: "...")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withSingleKey() {
		let keypath = Configuration.KeyPath(rawValue: "jira")
		XCTAssertNotNil(keypath)
	}

	func testKeyPathInit_withNormalPath() {
		let keypath = Configuration.KeyPath(rawValue: "jira.email")
		XCTAssertNotNil(keypath)
	}

	func testKeyPathInit_withNormalLongerPath() {
		let keypath = Configuration.KeyPath(rawValue: "jira.credentials.email")
		XCTAssertNotNil(keypath)
	}

	func testKeyPathInit_withSingleKeyAndDot() {
		let keypath = Configuration.KeyPath(rawValue: "jira.")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withDotAndSingleKey() {
		let keypath = Configuration.KeyPath(rawValue: ".jira")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withNormalPathAndDot() {
		let keypath = Configuration.KeyPath(rawValue: "jira.email.")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withDotAndNormalPath() {
		let keypath = Configuration.KeyPath(rawValue: ".jira.email")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withPathWithTwoDots() {
		let keypath = Configuration.KeyPath(rawValue: "jira..email")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withEmojiPath() {
		let keypath = Configuration.KeyPath(rawValue: "ji😎ra.email")
		XCTAssertNil(keypath)
	}

	// MARK: keys

	func testKeyPathKeys() {
		let keypath = Configuration.KeyPath(rawValue: "jira.email")
		XCTAssertEqual(keypath?.keys, ["jira", "email"])
	}

	// MARK: string literal init

	func testKeyPathStringLiteralInit() {
		let keypath: Configuration.KeyPath = "jira.email"
		XCTAssertNotNil(keypath)
	}
}
