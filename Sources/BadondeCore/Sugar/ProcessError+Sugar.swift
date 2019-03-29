import Foundation
import SwiftCLI
import GitHub
import Jira
import Sugar

extension ProcessError {
	public var exitStatus: Int32 {
		return 1
	}
}

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

extension URL.Error: ProcessError {
	public var message: String? {
		return localizedDescription.split(separator: "\n").map { "☛ " + $0 }.joined(separator: "\n")
	}
}

extension AppifyCommand.Error: ProcessError {
	var message: String? {
		return localizedDescription.split(separator: "\n").map { "☛ " + $0 }.joined(separator: "\n")
	}
}

extension BurghCommand.Error: ProcessError {
	var message: String? {
		return localizedDescription.split(separator: "\n").map { "☛ " + $0 }.joined(separator: "\n")
	}
}

extension PullRequestAnalyticsReporter.Error: ProcessError {
	var message: String? {
		return localizedDescription.split(separator: "\n").map { "☛ " + $0 }.joined(separator: "\n")
	}
}
