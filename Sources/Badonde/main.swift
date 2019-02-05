import Foundation
import BadondeCore

let tool = CommandLineTool()

do {
	try tool.run()
} catch {
	print("Whoops! An error occurred: \(error)")
}

RunLoop.main.run()
