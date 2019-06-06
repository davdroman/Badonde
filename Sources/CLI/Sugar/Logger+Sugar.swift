import Foundation
import enum BadondeKit.Log

extension Logger {
	static func logBadondefileLog(_ log: Log) {
		let indentationLevel = 3
		switch log {
		case .step(let description):
			step(indentationLevel: indentationLevel, description)
		case .info(let description):
			info(indentationLevel: indentationLevel, description)
		case .warn(let description):
			warn(indentationLevel: indentationLevel, description)
		case .fail(let description):
			fail(indentationLevel: indentationLevel, description)
		}
	}
}
