import XCTest
@testable import Configuration
import TestSugar

final class JSONFileInteractorMock: JSONFileInteractor {
	func read(from url: URL) throws -> [String: Any] {
		return [:]
	}

	func write(_ rawObject: [String: Any], to url: URL) throws {
		// NO-OP
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
}
