import Foundation
import SwiftCLI

let commandComponents = ["badonde", "burgh"] + CommandLine.arguments.dropFirst()

do {
	try run(bash: commandComponents.joined(separator: " "))
} catch {
	print(error)
}
