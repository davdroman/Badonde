import Foundation
import BadondeCore

let tool = CommandLineTool()

do {
	try tool.run()
} catch {
	print(error)
}

RunLoop.main.run()
