import Foundation
import SwiftCLI

do {
	var arguments = CommandLine.arguments // gets all arguments e.g. ["burgh", "-t", "123"]
	let command = arguments.removeFirst() // removes command path from arguments and saves it e.g. "burgh"
	let commandPath = try capture(bash: "which \(command)").stdout // finds command path e.g. "/usr/local/bin/burgh"
	var commandPathComponents = commandPath.split(separator: "/", maxSplits: .max, omittingEmptySubsequences: false).map(String.init) // splits command path into components e.g. ["/usr", "local", "bin", "burgh"]
	let burghCommand = commandPathComponents.removeLast() // removes command from command path and saves it e.g. ["/usr", "local", "bin"]
	commandPathComponents.append("badonde") // appends badonde command to alias' path e.g. ["/usr", "local", "bin", "badonde"]
	let badondeCommand = commandPathComponents.joined(separator: "/") // puts command back together e.g. "/usr/local/bin/badonde"

	let commandComponents = [badondeCommand, burghCommand] + arguments // e.g. ["/usr/local/bin/badonde", "burgh", "-t", "123"]
	try run(bash: commandComponents.joined(separator: " ")) // puts everything together and calls command e.g. "/usr/local/bin/badonde burgh -t 123"
} catch {
	print(error)
}
