import Foundation
import Jira

extension Ticket.Fields.IssueType {
	var isBug: Bool {
		return ["Bug", "Story Defect"].contains(name)
	}
}

extension Ticket.Key {
	init?(branchName: String) {
		guard let ticketId = branchName.split(separator: "_").first else {
			return nil
		}
		self.init(rawValue: String(ticketId))
	}
}

extension String {
	var isTicketBranch: Bool {
		return split(separator: "_").first?.contains("-") == true
	}
}
