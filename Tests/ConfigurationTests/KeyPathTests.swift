import XCTest
@testable import Configuration

final class KeyPathTests: XCTestCase {
	func testKeyPathInit_withEmptyPath() {
		let keypath = KeyPath(rawValue: "")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withDot() {
		let keypath = KeyPath(rawValue: ".")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withTwoDots() {
		let keypath = KeyPath(rawValue: "..")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withMultipleDots() {
		let keypath = KeyPath(rawValue: "...")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withSingleKey() {
		let keypath = KeyPath(rawValue: "jira")
		XCTAssertNotNil(keypath)
	}

	func testKeyPathInit_withNormalPath() {
		let keypath = KeyPath(rawValue: "jira.email")
		XCTAssertNotNil(keypath)
	}

	func testKeyPathInit_withNormalLongerPath() {
		let keypath = KeyPath(rawValue: "jira.credentials.email")
		XCTAssertNotNil(keypath)
	}

	func testKeyPathInit_withSingleKeyAndDot() {
		let keypath = KeyPath(rawValue: "jira.")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withDotAndSingleKey() {
		let keypath = KeyPath(rawValue: ".jira")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withNormalPathAndDot() {
		let keypath = KeyPath(rawValue: "jira.email.")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withDotAndNormalPath() {
		let keypath = KeyPath(rawValue: ".jira.email")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withPathWithTwoDots() {
		let keypath = KeyPath(rawValue: "jira..email")
		XCTAssertNil(keypath)
	}

	func testKeyPathInit_withEmojiPath() {
		let keypath = KeyPath(rawValue: "ji😎ra.email")
		XCTAssertNil(keypath)
	}
}

extension KeyPathTests {
	func testKeyPathStringLiteralInit() {
		let keypath: KeyPath = "jira.email"
		XCTAssertNotNil(keypath)
	}
}

extension KeyPathTests {
    func testKeyPathHashable() {
		let keyPathA = KeyPath(rawValue: "jira.email", description: "Jira email")!
		let keyPathB = KeyPath(rawValue: "jira.email")!
		let keyPathC = KeyPath(rawValue: "jira.accessToken")!
		let set = Set([keyPathA, keyPathB, keyPathC])
		XCTAssertEqual(set, [keyPathB, keyPathC])
		XCTAssertEqual(set, [keyPathA, keyPathC])
	}

	func testKeyPathEquatable() {
		let keyPathA = KeyPath(rawValue: "jira.email", description: "Jira email")!
		let keyPathB = KeyPath(rawValue: "jira.email")!
		let keyPathC = KeyPath(rawValue: "jira.accessToken")!
		XCTAssertTrue(keyPathA == keyPathB)
		XCTAssertFalse(keyPathA == keyPathC)
	}
}
