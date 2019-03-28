import Foundation
import Sugar

extension Ticket {
	public final class API {
		let email: String
		let apiToken: String
		var authorizationValue: String? {
			let rawString = [email, apiToken].joined(separator: ":")
			guard let utf8StringRepresentation = rawString.data(using: .utf8) else {
				return nil
			}
			return utf8StringRepresentation.base64EncodedString()
		}

		public init(email: String, apiToken: String) {
			self.email = email
			self.apiToken = apiToken
		}

		public func getTicket(with key: Key) throws -> Ticket {
			return try getTicket(with: key, expanded: true)
		}

		private func getTicket(with key: Key, expanded: Bool) throws -> Ticket {
			let url = try URL(
				scheme: "https",
				host: "asosmobile.atlassian.net",
				path: "/rest/api/2/issue/\(key.rawValue)",
				queryItems: expanded ? [URLQueryItem(name: "expand", value: "names")] : nil
			)

			guard let authorizationValue = authorizationValue else {
				throw Error.authorizationEncodingError
			}

			let session = URLSession(configuration: .default)
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.setValue("Basic \(authorizationValue)", forHTTPHeaderField: "Authorization")
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")

			let response = session.synchronousDataTask(with: request)

			if let error = response.error {
				throw Error.jiraConnectionFailed(error)
			}

			guard let jsonData = response.data else {
				throw Error.noDataReceived
			}

			var ticket = try JSONDecoder().decode(Ticket.self, from: jsonData)

			if let epicKey = ticket.fields.epicKey {
				let epic = try getTicket(with: epicKey, expanded: false)
				ticket.fields.epicSummary = epic.fields.summary
			} else if let parentTicketId = ticket.fields.parentTicket?.key {
				let parentTicket = try getTicket(with: parentTicketId, expanded: true)
				ticket.fields.epicSummary = parentTicket.fields.epicSummary
			}

			return ticket
		}
	}
}
