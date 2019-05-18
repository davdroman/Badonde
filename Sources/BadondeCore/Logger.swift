import Foundation
import CLISpinner

public final class Logger {
	private static let spinner = Spinner(pattern: .dots, color: .lightCyan, shouldHideCursor: false)
	private static var isStepping = false

	public class func step(_ description: String) {
		if isStepping {
			spinner.succeed()
		}
		spinner.pattern = Pattern(from: Pattern.dots.symbols.map { $0.applyingColor(.lightCyan) })
		spinner.text = description
		spinner.start()
		isStepping = true
	}

	public class func info(_ description: String, succeedPrevious: Bool = true) {
		if isStepping, succeedPrevious {
			spinner.succeed()
			isStepping = false
		}
		spinner.info(text: description)
	}

	public class func warn(_ description: String, succeedPrevious: Bool = true) {
		if isStepping, succeedPrevious {
			spinner.succeed()
			isStepping = false
		}
		spinner.warn(text: description)
	}

	public class func fail() {
		if isStepping {
			spinner.fail()
			isStepping = false
		}
	}

	public class func succeed() {
		if isStepping {
			spinner.succeed()
			isStepping = false
		}
	}
}
