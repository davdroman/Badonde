import Foundation
import SwiftCLI

let arguments = CommandLine.arguments.dropFirst().joined(separator: " ")

do {
	try run(bash: ["badonde", "burgh", arguments].joined(separator: " "))
} catch {
	print(error)
}
