import SwiftCLI
import GitHub
import Jira

// Explicit declaration needed for some reason.
// I think it might be a Swift bug but haven't dug into it.
extension GitHub.API.Error: ProcessError {
	public var message: String? {
		return localizedDescription.split(separator: "\n").map { "☛ " + $0 }.joined(separator: "\n")
	}
}

extension Jira.Ticket.API.Error: ProcessError {
	public var message: String? {
		return localizedDescription.split(separator: "\n").map { "☛ " + $0 }.joined(separator: "\n")
	}
}

extension ProcessError {
	public var message: String? {
		return localizedDescription.split(separator: "\n").map { "☛ " + $0 }.joined(separator: "\n")
	}

	public var exitStatus: Int32 {
		return 1
	}
}
