import Foundation
import BadondeCore

do {
	try CommandLineTool().run(with: ["burgh"] + CommandLine.arguments.dropFirst())
} catch {
	Logger.fail(error)
}
