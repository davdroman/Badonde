import Foundation
import Result

final class TicketFetcher {

	enum Error: Swift.Error {
		case noTicket
		case urlFormattingError
		case jiraConnection
		case noDataReceived
		case authorizationEncodingError
	}

	let email: String
	let apiToken: String
	var authorizationValue: String? {
		let rawString = [email, apiToken].joined(separator: ":")
		guard let utf8StringRepresentation = rawString.data(using: .utf8) else {
			return nil
		}
		return utf8StringRepresentation.base64EncodedString()
	}

	init(email: String, apiToken: String) {
		self.email = email
		self.apiToken = apiToken
	}

	func fetchTicket(with ticketId: TicketId) throws -> Ticket {
		guard ticketId.rawValue != "NO-TICKET" else {
			throw Error.noTicket
		}

		return try requestTicket(with: ticketId, expanded: true)
	}

	private func requestTicket(with ticketId: TicketId, expanded: Bool = false) throws -> Ticket {
		let jiraUrl = URL(
			scheme: "https",
			host: "asosmobile.atlassian.net",
			path: "/rest/api/2/issue/\(ticketId.rawValue)",
			queryItems: expanded ? [URLQueryItem(name: "expand", value: "names")] : nil
		)

		guard let url = jiraUrl else {
			throw Error.urlFormattingError
		}

		guard let authorizationValue = authorizationValue else {
			throw Error.authorizationEncodingError
		}

		let session = URLSession(configuration: .default)
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("Basic \(authorizationValue)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let response = session.synchronousDataTask(with: request)

		guard response.error == nil else {
			throw Error.jiraConnection
		}

		guard let jsonData = response.data else {
			throw Error.noDataReceived
		}

		var ticket = try JSONDecoder().decode(Ticket.self, from: jsonData)

		if let epicId = ticket.fields.epicId {
			let epic = try requestTicket(with: epicId)
			ticket.fields.epicSummary = epic.fields.summary
		} else if let parentTicketId = ticket.fields.parentTicket?.key {
			let parentTicket = try requestTicket(with: parentTicketId, expanded: true)
			ticket.fields.epicSummary = parentTicket.fields.epicSummary
		}

		return ticket
	}
}
