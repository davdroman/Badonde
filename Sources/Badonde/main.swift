import Foundation
import BadondeCore

do {
	try CommandLineTool().run()
} catch {
	Logger.fail(error)
}
