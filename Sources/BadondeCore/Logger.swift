//
//  Logger.swift
//  BadondeCore
//
//  Created by David Roman on 20/02/2019.
//

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
	}

	public class func fail(_ error: Error) {
		spinner?.fail()
		print(error.localizedDescription)
	}

	public class func finish() {
		spinner?.succeed()
	}
}
