import Foundation

extension Ticket.API {
	public enum Error {
		case jiraConnectionFailed(Swift.Error)
		case noDataReceived
		case authorizationEncodingError
	}
}

extension Ticket.API.Error: Swift.Error {
	public var localizedDescription: String {
		switch self {
		case .jiraConnectionFailed(let error):
			return "☛ JIRA API call failed with error: \(error)"
		case .noDataReceived:
			return "☛ No data received for JIRA API call"
		case .authorizationEncodingError:
			return "☛ JIRA authorization token encoding failed"
		}
	}
}
