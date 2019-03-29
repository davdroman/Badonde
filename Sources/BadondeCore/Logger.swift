import Foundation
import CLISpinner

public final class Logger {
	private static var spinner: Spinner?

	public class func step(_ description: String) {
		spinner?.succeed()
		spinner = Spinner(pattern: .dots, text: description, color: .lightCyan, shouldHideCursor: false)
		spinner?.start()
	}

	public class func info(_ description: String) {
		spinner?.info(text: description)
		spinner = nil
	}

	public class func fail() {
		spinner?.fail()
		spinner = nil
	}

	public class func finish() {
		spinner?.succeed()
		spinner = nil
	}
}
