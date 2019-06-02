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
		exit(EXIT_FAILURE)
	}
}

public enum Logger {
	static var printer: Printer = DefaultPrinter()

	public static func step(_ description: String) {
		printLog(.step(description))
	}

	public static func info(_ description: String) {
		printLog(.info(description))
	}

	public static func warn(_ description: String) {
		printLog(.warn(description))
	}

	public static func fail(_ description: String) {
		printLog(.fail(description))
	}

	static func printLog(_ log: Log) {
		printer.print(log.rawValue)
	}
}

public enum Log: Equatable, RawRepresentable {
	public enum Symbol {
		public static let step = "▶"
		public static let info = "ℹ"
		public static let warn = "⚠"
		public static let fail = "✖"

		public static let all = [step, info, warn, fail]
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
		case
			let .step(value),
			let .info(value),
			let .warn(value),
			let .fail(value): return value
		}
	}
}
