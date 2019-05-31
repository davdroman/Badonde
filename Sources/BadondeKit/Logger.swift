import Foundation
import Sugar

protocol Printer {
	func print(_ text: String)
}

final class DefaultPrinter: Printer {
	func print(_ text: String) {
		Swift.print(text)
	}
}

public func trySafely<T>(_ throwingClosure: () throws -> T) -> T {
	do {
		return try throwingClosure()
	} catch {
		Logger.fail(error.localizedDescription)

		// Avoid false-failure if used in unit tests.
		guard !ProcessInfo.isUnitTesting else {
			return () as! T
		}

		exit(EXIT_FAILURE)
	}
}

public enum Logger {
	public enum Log: Equatable, RawRepresentable {
		public enum Symbol {
			static let step = "▶"
			static let info = "ℹ"
			static let warn = "⚠"
			static let fail = "✖"
		}

		case step(String)
		case info(String)
		case warn(String)
		case fail(String)

		static let rawValueSeparator: Character = " "

		public var rawValue: String {
			return [caseSymbol, caseValue].joined(separator: String(Log.rawValueSeparator))
		}

		public init?(rawValue: String) {
			let components = rawValue
				.split(separator: Log.rawValueSeparator, maxSplits: 1, omittingEmptySubsequences: false)
				.map(String.init)

			switch (components.first, components.dropFirst().first) {
			case let (symbol?, value?):
				switch symbol {
				case Symbol.step: self = .step(value)
				case Symbol.info: self = .info(value)
				case Symbol.warn: self = .warn(value)
				case Symbol.fail: self = .fail(value)
				default: return nil
				}
			default:
				return nil
			}
		}

		var caseSymbol: String {
			switch self {
			case .step: return Symbol.step
			case .info: return Symbol.info
			case .warn: return Symbol.warn
			case .fail: return Symbol.fail
			}
		}

		var caseValue: String {
			switch self {
			case let .step(value),
				 let .info(value),
				 let .warn(value),
				 let .fail(value): return value
			}
		}
	}

	static var printer: Printer = DefaultPrinter()

	public static func step(_ description: String) {
		printer.print(Log.step(description).rawValue)
	}

	public static func info(_ description: String) {
		printer.print(Log.info(description).rawValue)
	}

	public static func warn(_ description: String) {
		printer.print(Log.warn(description).rawValue)
	}

	public static func fail(_ description: String) {
		printer.print(Log.fail(description).rawValue)
	}
}
