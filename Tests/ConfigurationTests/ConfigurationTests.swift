import XCTest
@testable import Configuration
import TestSugar

final class JSONFileInteractorSpy: JSONFileInteractor {
	typealias WriteSpy = ([String: Any], URL) -> Void

	var readFixture: FixtureLoadable
	var writeSpy: WriteSpy

	init(readFixture: FixtureLoadable, writeSpy: @escaping WriteSpy) {
		self.readFixture = readFixture
		self.writeSpy = writeSpy
	}

	func read(from url: URL) throws -> [String: Any] {
		return try readFixture.load(as: [String: Any].self)
	}

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

	func testInit_withEmptyFile() throws {
		let config = try Configuration(contentsOf: Fixture.empty.url, supportedKeyPaths: [])
		XCTAssertTrue(config.rawObject.isEmpty)
	}

	func testInit_withEmptyArrayFile() throws {
		let config = try Configuration(contentsOf: Fixture.emptyArray.url, supportedKeyPaths: [])
		XCTAssertTrue(config.rawObject.isEmpty)
	}

	func testInit_withEmptyDictionaryFile() throws {
		let config = try Configuration(contentsOf: Fixture.emptyDictionary.url, supportedKeyPaths: [])
		XCTAssertTrue(config.rawObject.isEmpty)
	}

	func testInit_withArrayFile() throws {
		let config = try Configuration(contentsOf: Fixture.array.url, supportedKeyPaths: [])
		XCTAssertTrue(config.rawObject.isEmpty)
	}
}

extension ConfigurationTests {
	func testGetRawValue_ofStringValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getRawValue(forKeyPath: .name)
		XCTAssertEqual(value, "David")
	}

	func testGetRawValue_ofIntValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getRawValue(forKeyPath: .age)
		XCTAssertEqual(value, "21")
	}

	func testGetRawValue_ofDoubleValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getRawValue(forKeyPath: .weight)
		XCTAssertEqual(value, "72.5")
	}

	func testGetRawValue_ofBoolValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])

		let valueA = try config.getRawValue(forKeyPath: .likesPepperoniPizza)
		XCTAssertEqual(valueA, "true")

		let valueB = try config.getRawValue(forKeyPath: .likesPineapplePizza)
		XCTAssertEqual(valueB, "false")
	}

	func testGetRawValue_ofArrayValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getRawValue(forKeyPath: .favoriteMovies)
		XCTAssertNil(value)
	}

	func testGetRawValue_ofStringValue_withNestedKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])

		let valueA = try config.getRawValue(forKeyPath: .bankDetails)
		XCTAssertNil(valueA)

		let valueB = try config.getRawValue(forKeyPath: .bankDetailsAccountNumber)
		XCTAssertEqual(valueB, "69696969")

		let valueC = try config.getRawValue(forKeyPath: .bankDetailsSortCode)
		XCTAssertEqual(valueC, "69-69-69")
	}

	func testGetRawValue_ofNullType_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getRawValue(forKeyPath: "iq")
		XCTAssertNil(value)
	}

	func testGetRawValue_withMissingPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getRawValue(forKeyPath: .likesGazpacho)
		XCTAssertNil(value)
	}
}

extension ConfigurationTests {
	func testGetValue_ofStringValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getValue(ofType: String.self, forKeyPath: .name)
		XCTAssertEqual(value, "David")
	}

	func testGetValue_ofIntValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getValue(ofType: Int.self, forKeyPath: .age)
		XCTAssertEqual(value, 21)
	}

	func testGetValue_ofDoubleValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getValue(ofType: Double.self, forKeyPath: .weight)
		XCTAssertEqual(value, 72.5)
	}

	func testGetValue_ofBoolValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])

		let valueA = try config.getValue(ofType: Bool.self, forKeyPath: .likesPepperoniPizza)
		XCTAssertEqual(valueA, true)

		let valueB = try config.getValue(ofType: Bool.self, forKeyPath: .likesPineapplePizza)
		XCTAssertEqual(valueB, false)
	}

	func testGetValue_ofArrayValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getValue(ofType: [String].self, forKeyPath: .favoriteMovies)
		XCTAssertNil(value)
	}

	func testGetValue_ofStringValue_withNestedKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])

		let valueA = try config.getValue(ofType: String.self, forKeyPath: .bankDetails)
		XCTAssertNil(valueA)

		let valueB = try config.getValue(ofType: String.self, forKeyPath: .bankDetailsAccountNumber)
		XCTAssertEqual(valueB, "69696969")

		let valueC = try config.getValue(ofType: String.self, forKeyPath: .bankDetailsSortCode)
		XCTAssertEqual(valueC, "69-69-69")
	}

	func testGetValue_ofNullType_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getValue(ofType: Int.self, forKeyPath: "iq")
		XCTAssertNil(value)
	}

	func testGetValue_withMissingPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		let value = try config.getValue(ofType: Bool.self, forKeyPath: .likesGazpacho)
		XCTAssertNil(value)
	}

	func testGetValue_ofInvalidBoolValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		XCTAssertThrowsError(try config.getValue(ofType: Bool.self, forKeyPath: .name)) { error in
			switch error {
			case let Configuration.Error.typeBridgingFailed(value, type):
				XCTAssert(value == "David")
				XCTAssert(type == Bool.self)
			default:
				XCTFail("`getValue` threw the wrong error")
			}
		}
	}

	func testGetValue_ofInvalidDoubleValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		XCTAssertThrowsError(try config.getValue(ofType: Double.self, forKeyPath: .name)) { error in
			switch error {
			case let Configuration.Error.typeBridgingFailed(value, type):
				XCTAssert(value == "David")
				XCTAssert(type == Double.self)
			default:
				XCTFail("`getValue` threw the wrong error")
			}
		}
	}

	func testGetValue_ofInvalidIntValue_withPlainKey() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		XCTAssertThrowsError(try config.getValue(ofType: Int.self, forKeyPath: .name)) { error in
			switch error {
			case let Configuration.Error.typeBridgingFailed(value, type):
				XCTAssert(value == "David")
				XCTAssert(type == Int.self)
			default:
				XCTFail("`getValue` threw the wrong error")
			}
		}
	}

	func testGetValue_ofInvalidBridgingType() throws {
		let config = try Configuration(contentsOf: Fixture.dictionary.url, supportedKeyPaths: [])
		XCTAssertThrowsError(try config.getValue(ofType: Date.self, forKeyPath: .name)) { error in
			switch error {
			case let Configuration.Error.invalidBridgingType(type):
				XCTAssert(type == Date.self)
			default:
				XCTFail("`getValue` threw the wrong error")
			}
		}
	}
}

extension ConfigurationTests {
	func testSetValue_ofStringValue_withNewPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setValue(5, forKeyPath: .socialSecurityNumber)
		let value = try config.getValue(ofType: Int.self, forKeyPath: .socialSecurityNumber)
		XCTAssertEqual(value, 5)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSetValue_ofStringValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setValue("Jack", forKeyPath: .name)
		let value = try config.getValue(ofType: String.self, forKeyPath: .name)
		XCTAssertEqual(value, "Jack")

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSetValue_ofIntValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setValue(25, forKeyPath: .age)
		let value = try config.getValue(ofType: Int.self, forKeyPath: .age)
		XCTAssertEqual(value, 25)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSetValue_ofDoubleValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setValue(72.5, forKeyPath: .weight)
		let value = try config.getValue(ofType: Double.self, forKeyPath: .weight)
		XCTAssertEqual(value, 72.5)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSetValue_ofBoolValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setValue(false, forKeyPath: .likesPepperoniPizza)
		let value = try config.getValue(ofType: Bool.self, forKeyPath: .likesPepperoniPizza)
		XCTAssertEqual(value, false)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSetValue_ofArrayValue_withPlainKey() throws {
		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in XCTFail("Config should not be written to") }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		XCTAssertThrowsError(
			try config.setValue(["The Devil Wears Prada"], forKeyPath: .favoriteMovies)
		) { error in
			switch error {
			case let Configuration.Error.invalidValueType(type):
				XCTAssert(type == [String].self)
			default:
				XCTFail("`setValue` threw the wrong error")
			}
		}
	}

	func testSetValue_ofStringValue_withNestedKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setValue("123456", forKeyPath: .bankDetailsAccountNumber)
		let value = try config.getValue(ofType: String.self, forKeyPath: .bankDetailsAccountNumber)
		XCTAssertEqual(value, "123456")

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSetValue_ofStringValue_withPartialNestedKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setValue("123", forKeyPath: .bankDetailsAccount)
		let value = try config.getValue(ofType: String.self, forKeyPath: .bankDetailsAccount)
		XCTAssertEqual(value, "123")

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSetValue_ofStringValue_withParentOfNestedKey() throws {
		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in XCTFail("Config should not be written to") }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		XCTAssertThrowsError(
			try config.setValue(3, forKeyPath: .bankDetails)
		) { error in
			switch error {
			case let Configuration.Error.incompatibleKeyPath(keyPath):
				XCTAssertEqual(keyPath.rawValue, "bank_details")
			default:
				XCTFail("`setValue` threw the wrong error")
			}
		}
	}
}

extension ConfigurationTests {
	func testSetRawValue_ofStringValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setRawValue("Jack", forKeyPath: .name)
		let value = try config.getValue(ofType: String.self, forKeyPath: .name)
		XCTAssertEqual(value, "Jack")

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSetRawValue_ofIntValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setRawValue("25", forKeyPath: .age)
		let value = try config.getValue(ofType: Int.self, forKeyPath: .age)
		XCTAssertEqual(value, 25)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSetRawValue_ofDoubleValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setValue("70.3", forKeyPath: .weight)
		let value = try config.getValue(ofType: Double.self, forKeyPath: .weight)
		XCTAssertEqual(value, 70.3)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSetRawValue_ofBoolValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")
		expectation.expectedFulfillmentCount = 2

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.setRawValue("false", forKeyPath: .likesPepperoniPizza)
		let valueA = try config.getValue(ofType: Bool.self, forKeyPath: .likesPepperoniPizza)
		XCTAssertEqual(valueA, false)

		try config.setRawValue("true", forKeyPath: .likesPineapplePizza)
		let valueB = try config.getValue(ofType: Bool.self, forKeyPath: .likesPineapplePizza)
		XCTAssertEqual(valueB, true)

		waitForExpectations(timeout: 1, handler: nil)
	}
}

extension ConfigurationTests {
	func testRemoveValue_withPlainKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.removeValue(forKeyPath: .likesPineapplePizza)
		let value = try config.getValue(ofType: Bool.self, forKeyPath: .likesPineapplePizza)
		XCTAssertNil(value)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testRemoveValue_withNestedKey() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in expectation.fulfill() }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		try config.removeValue(forKeyPath: .bankDetailsAccountNumber)
		let value = try config.getValue(ofType: Bool.self, forKeyPath: .bankDetailsAccountNumber)
		XCTAssertNil(value)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testRemoveValue_withParentOfNestedKey() throws {
		let fixture = Fixture.dictionary
		let interactor = JSONFileInteractorSpy(readFixture: fixture) { _, _ in XCTFail("Config should not be written to") }
		let config = try Configuration(contentsOf: fixture.url, supportedKeyPaths: [], fileInteractor: interactor)

		XCTAssertThrowsError(
			try config.removeValue(forKeyPath: .bankDetails)
		) { error in
			switch error {
			case let Configuration.Error.incompatibleKeyPath(keyPath):
				XCTAssertEqual(keyPath.rawValue, "bank_details")
			default:
				XCTFail("`removeValue` threw the wrong error")
			}
		}
	}
}

extension KeyPath {
	static let name: KeyPath = "name"
	static let age: KeyPath = "age"
	static let weight: KeyPath = "weight"

	static let likesPepperoniPizza: KeyPath = "likes_pepperoni_pizza"
	static let likesPineapplePizza: KeyPath = "likes_pineapple_pizza"
	static let favoriteMovies: KeyPath = "favorite_movies"

	static let bankDetails: KeyPath = "bank_details"
	static let bankDetailsAccount: KeyPath = "bank_details.account"
	static let bankDetailsAccountNumber: KeyPath = "bank_details.account_number"
	static let bankDetailsSortCode: KeyPath = "bank_details.sort_code"

	static let likesGazpacho: KeyPath = "likes_gazpacho"
	static let socialSecurityNumber: KeyPath = "social_security_number"
}
