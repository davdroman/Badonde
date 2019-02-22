import SwiftCLI

extension TicketFetcher{
	enum Error {
		case noTicketId
		case jiraConnectionFailed(Swift.Error)
		case noDataReceived
		case authorizationEncodingError
	}
}

extension TicketFetcher.Error: ProcessError {
	var message: String? {
		switch self {
		case .noTicketId:
			return "☛ Current branch is a 'NO-TICKET', please use a ticket prefixed branch"
		case .jiraConnectionFailed(let error):
			return "☛ JIRA API call failed with error: \(error)"
		case .noDataReceived:
			return "☛ No data received for JIRA API call"
		case .authorizationEncodingError:
			return "☛ JIRA authorization token encoding failed"
		}
	}
}
