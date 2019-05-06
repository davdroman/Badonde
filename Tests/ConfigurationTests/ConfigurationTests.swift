import XCTest
@testable import Configuration
import TestSugar

final class JSONFileInteractorSpy: JSONFileInteractor {
	typealias WriteSpy = ([String: Any], URL) -> Void

	init(readFixture: FixtureLoadable, writeSpy: @escaping WriteSpy) {
		self.readFixture = readFixture
		self.writeSpy = writeSpy
	}

	var readFixture: FixtureLoadable
	func read(from url: URL) throws -> [String: Any] {
		return try readFixture.load(as: [String: Any].self)
	}

	var writeSpy: WriteSpy
	func write(_ rawObject: [String: Any], to url: URL) throws {
		writeSpy(rawObject, url)
	}
}

final class ConfigurationTests: XCTestCase {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }

		case empty
		case emptyArray = "empty_array"
		case emptyDictionary = "empty_dictionary"
		case array
		case dictionary
	}

	func testConfigurationInit_withEmptyFile() throws {
		let config = try Configuration(contentsOf: Fixture.empty.url)
		XCTAssertTrue(config.rawObject.isEmpty)
	}

	func testConfigurationInit_withEmptyArrayFile() throws {
		let config = try Configuration(contentsOf: Fixture.emptyArray.url)
		XCTAssertTrue(config.rawObject.isEmpty)
	}

	func testConfigurationInit_withEmptyDictionaryFile() throws {
		let config = try Configuration(contentsOf: Fixture.emptyDictionary.url)
		XCTAssertTrue(config.rawObject.isEmpty)
	}

	func testConfigurationInit_withArrayFile() throws {
		let config = try Configuration(contentsOf: Fixture.array.url)
		XCTAssertTrue(config.rawObject.isEmpty)
	}

	// MARK: getRawValue

	func testConfigurationGetRawValue_ofStringValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = config.getRawValue(forKeyPath: "name")
		XCTAssertEqual(value, "David")
	}

	func testConfigurationGetRawValue_ofIntValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = config.getRawValue(forKeyPath: "age")
		XCTAssertEqual(value, "21")
	}

	func testConfigurationGetRawValue_ofDoubleValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = config.getRawValue(forKeyPath: "weight")
		XCTAssertEqual(value, "72.5")
	}

	func testConfigurationGetRawValue_ofBoolValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)

		let valueA = config.getRawValue(forKeyPath: "likes_pepperoni_pizza")
		XCTAssertEqual(valueA, "true")

		let valueB = config.getRawValue(forKeyPath: "likes_pineapple_pizza")
		XCTAssertEqual(valueB, "false")
	}

	func testConfigurationGetRawValue_ofArrayValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = config.getRawValue(forKeyPath: "favorite_movies")
		XCTAssertNil(value)
	}

	func testConfigurationGetRawValue_ofStringValue_withNestedKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)

		let valueA = config.getRawValue(forKeyPath: "bank_details")
		XCTAssertNil(valueA)

		let valueB = config.getRawValue(forKeyPath: "bank_details.account_number")
		XCTAssertEqual(valueB, "69696969")

		let valueC = config.getRawValue(forKeyPath: "bank_details.sort_code")
		XCTAssertEqual(valueC, "69-69-69")
	}

	func testConfigurationGetRawValue_ofNullType_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = config.getRawValue(forKeyPath: "iq")
		XCTAssertNil(value)
	}

	func testConfigurationGetRawValue_withMissingPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = config.getRawValue(forKeyPath: "likes_gazpacho")
		XCTAssertNil(value)
	}

	// MARK: getValue

	func testConfigurationGetValue_ofStringValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = try config.getValue(ofType: String.self, forKeyPath: "name")
		XCTAssertEqual(value, "David")
	}

	func testConfigurationGetValue_ofIntValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = try config.getValue(ofType: Int.self, forKeyPath: "age")
		XCTAssertEqual(value, 21)
	}

	func testConfigurationGetValue_ofDoubleValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = try config.getValue(ofType: Double.self, forKeyPath: "weight")
		XCTAssertEqual(value, 72.5)
	}

	func testConfigurationGetValue_ofBoolValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)

		let valueA = try config.getValue(ofType: Bool.self, forKeyPath: "likes_pepperoni_pizza")
		XCTAssertEqual(valueA, true)

		let valueB = try config.getValue(ofType: Bool.self, forKeyPath: "likes_pineapple_pizza")
		XCTAssertEqual(valueB, false)
	}

	func testConfigurationGetValue_ofArrayValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = try config.getValue(ofType: [String].self, forKeyPath: "favorite_movies")
		XCTAssertNil(value)
	}

	func testConfigurationGetValue_ofStringValue_withNestedKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)

		let valueA = try config.getValue(ofType: String.self, forKeyPath: "bank_details")
		XCTAssertNil(valueA)

		let valueB = try config.getValue(ofType: String.self, forKeyPath: "bank_details.account_number")
		XCTAssertEqual(valueB, "69696969")

		let valueC = try config.getValue(ofType: String.self, forKeyPath: "bank_details.sort_code")
		XCTAssertEqual(valueC, "69-69-69")
	}

	func testConfigurationGetValue_ofNullType_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = try config.getValue(ofType: Int.self, forKeyPath: "iq")
		XCTAssertNil(value)
	}

	func testConfigurationGetValue_withMissingPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		let value = try config.getValue(ofType: Bool.self, forKeyPath: "likes_gazpacho")
		XCTAssertNil(value)
	}

	func testConfigurationGetValue_ofInvalidBoolValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		XCTAssertThrowsError(try config.getValue(ofType: Bool.self, forKeyPath: "name")) { error in
			switch error {
			case let Configuration.Error.typeBridgingFailed(value, type):
				XCTAssert(value == "David")
				XCTAssert(type == Bool.self)
			default:
				XCTFail()
			}
		}
	}

	func testConfigurationGetValue_ofInvalidDoubleValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		XCTAssertThrowsError(try config.getValue(ofType: Double.self, forKeyPath: "name")) { error in
			switch error {
			case let Configuration.Error.typeBridgingFailed(value, type):
				XCTAssert(value == "David")
				XCTAssert(type == Double.self)
			default:
				XCTFail()
			}
		}
	}

	func testConfigurationGetValue_ofInvalidIntValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		XCTAssertThrowsError(try config.getValue(ofType: Int.self, forKeyPath: "name")) { error in
			switch error {
			case let Configuration.Error.typeBridgingFailed(value, type):
				XCTAssert(value == "David")
				XCTAssert(type == Int.self)
			default:
				XCTFail()
			}
		}
	}

	func testConfigurationGetValue_ofInvalidBridgingType() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url)
		XCTAssertThrowsError(try config.getValue(ofType: Date.self, forKeyPath: "name")) { error in
			switch error {
			case let Configuration.Error.invalidBridgingType(type):
				XCTAssert(type == Date.self)
			default:
				XCTFail()
			}
		}
	}

	// MARK: setValue

	func testConfigurationSetValue_ofStringValue_withNewPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setValue(5, forKeyPath: "social_security_number")
		let value = try config.getValue(ofType: Int.self, forKeyPath: "social_security_number")
		XCTAssertEqual(value, 5)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testConfigurationSetValue_ofStringValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setValue("Jack", forKeyPath: "name")
		let value = try config.getValue(ofType: String.self, forKeyPath: "name")
		XCTAssertEqual(value, "Jack")

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testConfigurationSetValue_ofIntValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setValue(25, forKeyPath: "age")
		let value = try config.getValue(ofType: Int.self, forKeyPath: "age")
		XCTAssertEqual(value, 25)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testConfigurationSetValue_ofDoubleValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setValue(72.5, forKeyPath: "weight")
		let value = try config.getValue(ofType: Double.self, forKeyPath: "weight")
		XCTAssertEqual(value, 72.5)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testConfigurationSetValue_ofBoolValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setValue(false, forKeyPath: "likes_pepperoni_pizza")
		let value = try config.getValue(ofType: Bool.self, forKeyPath: "likes_pepperoni_pizza")
		XCTAssertEqual(value, false)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testConfigurationSetValue_ofArrayValue_withPlainKey() throws {
		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in XCTFail() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		XCTAssertThrowsError(
			try config.setValue(["The Devil Wears Prada"], forKeyPath: "favorite_movies")
		) { error in
			switch error {
			case let Configuration.Error.invalidValueType(type):
				XCTAssert(type == [String].self)
			default:
				XCTFail()
			}
		}
	}

	func testConfigurationSetValue_ofStringValue_withNestedKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setValue("123456", forKeyPath: "bank_details.account_number")
		let value = try config.getValue(ofType: String.self, forKeyPath: "bank_details.account_number")
		XCTAssertEqual(value, "123456")

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testConfigurationSetValue_ofStringValue_withPartialNestedKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setValue("123", forKeyPath: "bank_details.account")
		let value = try config.getValue(ofType: String.self, forKeyPath: "bank_details.account")
		XCTAssertEqual(value, "123")

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testConfigurationSetValue_ofStringValue_withParentOfNestedKey() throws {
		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in XCTFail() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		XCTAssertThrowsError(
			try config.setValue(3, forKeyPath: "bank_details")
		) { error in
			switch error {
			case let Configuration.Error.incompatibleKeyPath(keyPath):
				XCTAssertEqual(keyPath.rawValue, "bank_details")
			default:
				XCTFail()
			}
		}
	}

	// MARK: setRawValue

	func testConfigurationSetRawValue_ofStringValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setRawValue("Jack", forKeyPath: "name")
		let value = try config.getValue(ofType: String.self, forKeyPath: "name")
		XCTAssertEqual(value, "Jack")

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testConfigurationSetRawValue_ofIntValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setRawValue("25", forKeyPath: "age")
		let value = try config.getValue(ofType: Int.self, forKeyPath: "age")
		XCTAssertEqual(value, 25)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testConfigurationSetRawValue_ofDoubleValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setValue("70.3", forKeyPath: "weight")
		let value = try config.getValue(ofType: Double.self, forKeyPath: "weight")
		XCTAssertEqual(value, 70.3)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testConfigurationSetRawValue_ofBoolValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")
		expectation.expectedFulfillmentCount = 2

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, fileInteractor: interactor)

		try config.setRawValue("false", forKeyPath: "likes_pepperoni_pizza")
		let valueA = try config.getValue(ofType: Bool.self, forKeyPath: "likes_pepperoni_pizza")
		XCTAssertEqual(valueA, false)

		try config.setRawValue("true", forKeyPath: "likes_pineapple_pizza")
		let valueB = try config.getValue(ofType: Bool.self, forKeyPath: "likes_pineapple_pizza")
		XCTAssertEqual(valueB, true)

		waitForExpectations(timeout: 1, handler: nil)
	}
}
