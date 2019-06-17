import Foundation
import CLISpinner

public enum Logger {
	private static let pattern = Pattern.dots
	private static let spinner = Spinner(pattern: pattern, color: .lightCyan)

	private static var isStepping = false
	private static var currentIndentationLevel = 0
	private static var currentIndentation: String {
		return String(repeating: " ", count: currentIndentationLevel)
	}

	public static func step(indentationLevel: Int = 0, _ description: String) {
		if isStepping {
			spinner.succeed(indentation: currentIndentation)
			spinner.text = description
		} else {
			spinner._text = description
		}
		currentIndentationLevel = indentationLevel
		spinner.pattern = Pattern(from: pattern.symbols.map { currentIndentation + $0.applyingColor(.lightCyan) })
		spinner.start()
		isStepping = true
	}

	public static func info(indentationLevel: Int = 0, _ description: String, succeedPrevious: Bool = true) {
		if isStepping, succeedPrevious {
			spinner.succeed(indentation: currentIndentation)
		}
		currentIndentationLevel = indentationLevel
		spinner.info(indentation: currentIndentation, text: description)
		isStepping = false
	}

	public static func warn(indentationLevel: Int = 0, _ description: String, succeedPrevious: Bool = true) {
		if isStepping, succeedPrevious {
			spinner.succeed(indentation: currentIndentation)
		}
		currentIndentationLevel = indentationLevel
		spinner.warn(indentation: currentIndentation, text: description)
		isStepping = false
	}

	public static func fail(indentationLevel: Int = 0, _ description: String) {
		if isStepping {
			spinner.fail(indentation: currentIndentation)
			isStepping = false
		} else {
			currentIndentationLevel = indentationLevel
			spinner.fail(text: "An error ocurred", indentation: currentIndentation)
		}

		let prettifiedErrorDescription = description
			.components(separatedBy: "\n")
			.map { currentIndentation + "☛ " + $0 }
			.joined(separator: "\n")

		fputs(prettifiedErrorDescription + "\n", stderr)
	}

	public static func succeed() {
		if isStepping {
			spinner.succeed(indentation: currentIndentation)
			isStepping = false
		}
	}

	public static func finish() {
		spinner.unhideCursor()
	}
}

private extension Spinner {
	func succeed(indentation: String) {
		stop(symbol: indentation + "✔".green)
	}

	func fail(text: String? = nil, indentation: String) {
		stop(text: indentedText(indentation, text), symbol: indentation + "✖".red)
	}

	func warn(indentation: String, text: String? = nil) {
		stop(text: indentedText(indentation, text), symbol: indentation + "⚠".yellow)
	}

	func info(indentation: String, text: String? = nil) {
		stop(text: indentedText(indentation, text), symbol: indentation + "ℹ".blue)
	}

	private func indentedText(_ indentation: String, _ text: String?) -> String? {
		let symbolIndentation = String(repeating: " ", count: 2)
		return text?
			.components(separatedBy: "\n")
			.enumerated()
			.map { $0.offset > 0 ? indentation + symbolIndentation + $0.element : $0.element }
			.joined(separator: "\n")
	}
}
