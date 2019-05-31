import XCTest
@testable import BadondeKit

final class PrinterSpy: Printer {
	let printSpy: ((String) -> Void)

	init(printSpy: @escaping ((String) -> Void)) {
		self.printSpy = printSpy
	}

	func print(_ text: String) {
		printSpy(text)
	}
}

final class LoggerTests: XCTestCase {
	func testLogInit_stepSymbol() {
		let log = Log(rawValue: "▶ something")
		XCTAssertEqual(log, .step("something"))
	}

	func testLogInit_infoSymbol() {
		let log = Log(rawValue: "ℹ something")
		XCTAssertEqual(log, .info("something"))
	}

	func testLogInit_warnSymbol() {
		let log = Log(rawValue: "⚠ something")
		XCTAssertEqual(log, .warn("something"))
	}

	func testLogInit_failSymbol() {
		let log = Log(rawValue: "✖ something")
		XCTAssertEqual(log, .fail("something"))
	}

	func testLogInit_invalidSymbol() {
		let log = Log(rawValue: "- something")
		XCTAssertNil(log)
	}

	func testLogInit_validSymbol_repeated() {
		let logA = Log(rawValue: "▶▶ something")
		let logB = Log(rawValue: "▶ ▶ something")
		let logC = Log(rawValue: "▶ ▶▶ something")
		let logD = Log(rawValue: "▶ ▶ ▶ something")

		XCTAssertNil(logA)
		XCTAssertEqual(logB, .step("▶ something"))
		XCTAssertEqual(logC, .step("▶▶ something"))
		XCTAssertEqual(logD, .step("▶ ▶ something"))
	}

	func testLogInit_validSymbol_emptyDescription() {
		let log = Log(rawValue: "▶ ")
		XCTAssertEqual(log, .step(""))
	}
}

extension LoggerTests {
	func testStep() {
		let expectation = self.expectation(description: "Printing function is invoked")

		Logger.printer = PrinterSpy {
			XCTAssertEqual($0, "▶ Uno: el brikindans")
			expectation.fulfill()
		}

		Logger.step("Uno: el brikindans")
		waitForExpectations(timeout: 2, handler: nil)
	}

	func testInfo() {
		let expectation = self.expectation(description: "Printing function is invoked")

		Logger.printer = PrinterSpy {
			XCTAssertEqual($0, "ℹ Dos: el crusaíto")
			expectation.fulfill()
		}

		Logger.info("Dos: el crusaíto")
		waitForExpectations(timeout: 2, handler: nil)
	}

	func testWarn() {
		let expectation = self.expectation(description: "Printing function is invoked")

		Logger.printer = PrinterSpy {
			XCTAssertEqual($0, "⚠ Tres: el Maiquelyason")
			expectation.fulfill()
		}

		Logger.warn("Tres: el Maiquelyason")
		waitForExpectations(timeout: 2, handler: nil)
	}

	func testFail() {
		let expectation = self.expectation(description: "Printing function is invoked")

		Logger.printer = PrinterSpy {
			XCTAssertEqual($0, "✖ Cuatro: el Robocop")
			expectation.fulfill()
		}

		Logger.fail("Cuatro: el Robocop")
		waitForExpectations(timeout: 2, handler: nil)
	}
}
