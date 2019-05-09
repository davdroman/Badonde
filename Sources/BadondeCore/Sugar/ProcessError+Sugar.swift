import Foundation
import SwiftCLI
import Git
import GitHub
import Jira
import Sugar

extension ProcessError {
	public var message: String? {
		return localizedDescription.prettify()
	}

	public var exitStatus: Int32 {
		return 1
	}
}

// Explicit declaration needed given Swift's static nature.

extension Git.Branch.Error: ProcessError {
	public var message: String? {
		return localizedDescription.prettify()
	}
}

extension Git.Diff.Error: ProcessError {
	public var message: String? {
		return localizedDescription.prettify()
	}
}

extension Git.Commit.Error: ProcessError {
	public var message: String? {
		return localizedDescription.prettify()
	}
}

extension GitHub.API.Error: ProcessError {
	public var message: String? {
		return localizedDescription.prettify()
	}
}

extension GitHub.Repository.Shorthand.Error: ProcessError {
	public var message: String? {
		return localizedDescription.prettify()
	}
}

extension Jira.Ticket.API.Error: ProcessError {
	public var message: String? {
		return localizedDescription.prettify()
	}
}

extension URL.Error: ProcessError {
	public var message: String? {
		return localizedDescription.prettify()
	}
}

extension AppifyCommand.Error: ProcessError {
	var message: String? {
		return localizedDescription.prettify()
	}
}

extension BurghCommand.Error: ProcessError {
	var message: String? {
		return localizedDescription.prettify()
	}
}

extension ConfigCommand.Error: ProcessError {
	var message: String? {
		return localizedDescription.prettify()
	}
}

extension PullRequest.AnalyticsReporter.Error: ProcessError {
	var message: String? {
		return localizedDescription.prettify()
	}
}

private extension String {
	func prettify() -> String {
		return components(separatedBy: "\n").map { "☛ " + $0 }.joined(separator: "\n")
	}
}
