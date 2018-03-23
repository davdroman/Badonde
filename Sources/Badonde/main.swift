import BadondeCore
import Foundation

do {
	try Badonde().run()
} catch {
	print("Error: \(error)")
}
