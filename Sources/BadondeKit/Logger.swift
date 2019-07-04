import Foundation

protocol Printer {
	func print(_ text: String)
}

final class DefaultPrinter: Printer {
	func print(_ text: String) {
		Swift.print(text)
		fflush(stdout)
	}
}

/// Attempts to execute a function without propagating thrown errors
/// to the top level, and exiting the program safely instead.
public func trySafely<T>(_ throwingClosure: () throws -> T) -> T {
	do {
		return try throwingClosure()
	} catch {
		Logger.failAndExit(error.localizedDescription)
	}
}

extension Logger {
	public static func failAndExit(_ errorMessage: String) -> Never {
		Logger.fail(errorMessage)
		exit(EXIT_FAILURE)
	}
}

/// A namespace collecting logging functions.
///
/// This class allows the user to print steps throughout Badondefile's
/// evaluation for further insight on its execution.
public enum Logger {
	static var printer: Printer = DefaultPrinter()

	/// Prints loading dots followed by the given description to
	/// indicate an activity in progress.
	///
	/// - Parameter description: the log description.
	public static func step(_ description: String) {
		printLog(.step(description))
	}

	/// Prints an info sign followed by the given description.
	///
	/// If `Logger.step` was ocurring before this call, said output
	/// will be ticked off as successfully completed.
	///
	/// - Parameter description: the log description.
	public static func info(_ description: String) {
		printLog(.info(description))
	}

	/// Prints a warning sign followed by the given description.
	///
	/// If `Logger.step` was ocurring before this call, said output
	/// will be ticked off as successfully completed.
	///
	/// - Parameter description: the log description.
	public static func warn(_ description: String) {
		printLog(.warn(description))
	}

	/// Fails the previously executing step (if existing), and prints
	/// the specified description of what went wrong in the following
	/// line.
	///
	/// - Parameter description: the log description.
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
