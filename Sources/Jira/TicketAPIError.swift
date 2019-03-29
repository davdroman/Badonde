import Foundation

extension Ticket.API {
	public enum Error {
		case authorizationEncodingError
		case http(Int)
	}
}

extension Ticket.API.Error: Swift.Error {
	public var localizedDescription: String {
		switch self {
		case .authorizationEncodingError:
			return "JIRA authorization token encoding failed"
		case .http(let statusCode):
			return "JIRA API call failed with HTTP status code \(statusCode)"
		}
	}
}
