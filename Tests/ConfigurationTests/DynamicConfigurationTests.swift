import XCTest
@testable import Configuration
import TestSugar

final class DynamicConfigurationTests: XCTestCase {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }

		case configA = "config_a"
		case configB = "config_b"
	}
}

extension DynamicConfigurationTests {
	func testGetRawValue_fromConfigA() throws {
		let configA = try Configuration(contentsOfFile: Fixture.configA.path, supportedKeyPaths: [])
		let configB = try Configuration(contentsOfFile: Fixture.configB.path, supportedKeyPaths: [])
		let dynamicConfig = try DynamicConfiguration(prioritizedConfigurations: [configA, configB])

		let value = try dynamicConfig.getRawValue(forKeyPath: .name)
		XCTAssertEqual(value, "David")
	}

	func testGetRawValue_fromConfigB() throws {
		let configA = try Configuration(contentsOfFile: Fixture.configA.path, supportedKeyPaths: [])
		let configB = try Configuration(contentsOfFile: Fixture.configB.path, supportedKeyPaths: [])
		let dynamicConfig = try DynamicConfiguration(prioritizedConfigurations: [configA, configB])

		let value = try dynamicConfig.getRawValue(forKeyPath: .age)
		XCTAssertEqual(value, "21")
	}
}

extension DynamicConfigurationTests {
	func testGetValue_fromConfigA() throws {
		let configA = try Configuration(contentsOfFile: Fixture.configA.path, supportedKeyPaths: [])
		let configB = try Configuration(contentsOfFile: Fixture.configB.path, supportedKeyPaths: [])
		let dynamicConfig = try DynamicConfiguration(prioritizedConfigurations: [configA, configB])

		let value = try dynamicConfig.getValue(ofType: String.self, forKeyPath: .name)
		XCTAssertEqual(value, "David")
	}

	func testGetValue_fromConfigB() throws {
		let configA = try Configuration(contentsOfFile: Fixture.configA.path, supportedKeyPaths: [])
		let configB = try Configuration(contentsOfFile: Fixture.configB.path, supportedKeyPaths: [])
		let dynamicConfig = try DynamicConfiguration(prioritizedConfigurations: [configA, configB])

		let value = try dynamicConfig.getValue(ofType: Int.self, forKeyPath: .age)
		XCTAssertEqual(value, 21)
	}

	func testGetValue_ofInvalidBridgingTypeInConfigA_fromConfigB() throws {
		let configA = try Configuration(contentsOfFile: Fixture.configA.path, supportedKeyPaths: [])
		let configB = try Configuration(contentsOfFile: Fixture.configB.path, supportedKeyPaths: [])
		let dynamicConfig = try DynamicConfiguration(prioritizedConfigurations: [configA, configB])

		XCTAssertThrowsError(try dynamicConfig.getValue(ofType: Bool.self, forKeyPath: .likesPepperoniPizza)) { error in
			switch error {
			case let Configuration.Error.typeBridgingFailed(value, type):
				XCTAssertEqual(value, "maybe")
				XCTAssert(type == Bool.self)
			default:
				XCTFail("`getValue` threw the wrong error")
			}
		}
	}
}

extension DynamicConfigurationTests {
	func testSetValue_toConfigA() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let configAFixture = Fixture.configA
		let configAInteractor = JSONFileInteractorSpy(readFixture: configAFixture) { _, _ in expectation.fulfill() }
		let configA = try Configuration(contentsOfFile: configAFixture.path, supportedKeyPaths: [], fileInteractor: configAInteractor)

		let configBFixture = Fixture.configB
		let configBInteractor = JSONFileInteractorSpy(readFixture: configAFixture) { _, _ in XCTFail("Config B should not be written to") }
		let configB = try Configuration(contentsOfFile: configBFixture.path, supportedKeyPaths: [], fileInteractor: configBInteractor)

		let dynamicConfig = try DynamicConfiguration(prioritizedConfigurations: [configA, configB])

		try dynamicConfig.setValue("Jack", forKeyPath: .name)
		let value = try configA.getValue(ofType: String.self, forKeyPath: .name)
		XCTAssertEqual(value, "Jack")

		waitForExpectations(timeout: 1, handler: nil)
	}
}

extension DynamicConfigurationTests {
	func testSetRawValue_toConfigA() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let configAFixture = Fixture.configA
		let configAInteractor = JSONFileInteractorSpy(readFixture: configAFixture) { _, _ in expectation.fulfill() }
		let configA = try Configuration(contentsOfFile: configAFixture.path, supportedKeyPaths: [], fileInteractor: configAInteractor)

		let configBFixture = Fixture.configB
		let configBInteractor = JSONFileInteractorSpy(readFixture: configAFixture) { _, _ in XCTFail("Config B should not be written to") }
		let configB = try Configuration(contentsOfFile: configBFixture.path, supportedKeyPaths: [], fileInteractor: configBInteractor)

		let dynamicConfig = try DynamicConfiguration(prioritizedConfigurations: [configA, configB])

		try dynamicConfig.setRawValue("Jack", forKeyPath: .name)
		let value = try configA.getValue(ofType: String.self, forKeyPath: .name)
		XCTAssertEqual(value, "Jack")

		waitForExpectations(timeout: 1, handler: nil)
	}
}

extension DynamicConfigurationTests {
	func testRemoveValue_fromConfigA() throws {
		let expectation = self.expectation(description: "File is written after setting value")

		let configAFixture = Fixture.configA
		let configAInteractor = JSONFileInteractorSpy(readFixture: configAFixture) { _, _ in expectation.fulfill() }
		let configA = try Configuration(contentsOfFile: configAFixture.path, supportedKeyPaths: [], fileInteractor: configAInteractor)

		let configBFixture = Fixture.configB
		let configBInteractor = JSONFileInteractorSpy(readFixture: configAFixture) { _, _ in XCTFail("Config B should not be written to") }
		let configB = try Configuration(contentsOfFile: configBFixture.path, supportedKeyPaths: [], fileInteractor: configBInteractor)

		let dynamicConfig = try DynamicConfiguration(prioritizedConfigurations: [configA, configB])

		try dynamicConfig.removeValue(forKeyPath: .likesPineapplePizza)
		let value = try configA.getValue(ofType: Bool.self, forKeyPath: .likesPineapplePizza)
		XCTAssertNil(value)

		waitForExpectations(timeout: 1, handler: nil)
	}
}
