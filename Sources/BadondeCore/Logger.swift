import Foundation
import CLISpinner

public enum Logger {
	private static let spinner = Spinner(pattern: .dots, color: .lightCyan)
	private static var isStepping = false

	public static func step(_ description: String) {
		if isStepping {
			spinner.succeed()
			spinner.text = description
		} else {
			spinner._text = description
		}
		spinner.pattern = Pattern(from: Pattern.dots.symbols.map { $0.applyingColor(.lightCyan) })
		spinner.start()
		isStepping = true
	}

	public static func info(_ description: String, succeedPrevious: Bool = true) {
		if isStepping, succeedPrevious {
			spinner.succeed()
		}
		spinner.info(text: description)
		isStepping = false
	}

	public static func warn(_ description: String, succeedPrevious: Bool = true) {
		if isStepping, succeedPrevious {
			spinner.succeed()
		}
		spinner.warn(text: description)
		isStepping = false
	}

	public static func fail(_ description: String) {
		if isStepping {
			spinner.fail()
			isStepping = false
		}

		let prettifiedErrorDescription = description
			.components(separatedBy: "\n")
			.map { "☛ " + $0 }
			.joined(separator: "\n")

		fputs(prettifiedErrorDescription + "\n", stderr)
	}

	public static func succeed() {
		if isStepping {
			spinner.succeed()
			isStepping = false
		}
	}

	public static func finish() {
		spinner.unhideCursor()
	}
}
