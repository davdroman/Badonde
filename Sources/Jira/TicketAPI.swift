import Foundation
import Sugar

extension Ticket {
	public final class API {
		let organization: String
		let email: String
		let apiToken: String
		var authorizationValue: String {
			return [email, apiToken].joined(separator: ":").base64()
		}

		public init(organization: String, email: String, apiToken: String) {
			self.organization = organization
			self.email = email
			self.apiToken = apiToken
		}

		public func getTicket(with key: Key) throws -> Ticket {
			return try getTicket(with: key, expanded: true)
		}

		private func getTicket(with key: Key, expanded: Bool) throws -> Ticket {
			let url = try URL(
				scheme: "https",
				host: "\(organization).atlassian.net",
				path: "/rest/api/2/issue/\(key.rawValue)",
				queryItems: expanded ? [URLQueryItem(name: "expand", value: "names")] : nil
			)

			let session = URLSession(configuration: .default)
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.setValue("Basic \(authorizationValue)", forHTTPHeaderField: "Authorization")
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")

			let resultValue = try session.synchronousDataTask(with: request).get()
			let statusCode = (resultValue.response as? HTTPURLResponse)?.statusCode ?? 200

			guard !(400...599).contains(statusCode) else {
				throw Error.http(statusCode)
			}

			var ticket = try JSONDecoder().decode(Ticket.self, from: resultValue.data)

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

extension Ticket.API {
	public enum Error {
		case http(Int)
	}
}

extension Ticket.API.Error: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .http(let statusCode):
			return "JIRA API call failed with HTTP status code \(statusCode)"
		}
	}
}
