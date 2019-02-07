//
//  TicketFetcher.swift
//  BadondeCore
//
//  Created by David Roman on 04/02/2019.
//

import Foundation
import Result

final class TicketFetcher {

	enum Error: Swift.Error {
		case noTicket
		case urlFormattingError
		case jiraConnection
		case noDataReceived
		case ticketParsingError
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

	func fetchTicket(
		with ticketId: TicketId,
		completion: @escaping (Result<Ticket, Error>) -> Void
	) {
		guard ticketId.rawValue != "NO-TICKET" else {
			completion(.failure(Error.noTicket))
			return
		}

		requestTicket(with: ticketId, expanded: true, completion: completion)
	}

	private func requestTicket(
		with ticketId: TicketId,
		expanded: Bool = false,
		completion: @escaping (Result<Ticket, Error>) -> Void
	) {
		let jiraUrl = URL(
			scheme: "https",
			host: "asosmobile.atlassian.net",
			path: "/rest/api/2/issue/\(ticketId.rawValue)",
			queryItems: expanded ? [URLQueryItem(name: "expand", value: "names")] : nil
		)

		guard let url = jiraUrl else {
			completion(.failure(Error.urlFormattingError))
			return
		}

		guard let authorizationValue = authorizationValue else {
			completion(.failure(Error.authorizationEncodingError))
			return
		}

		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("Basic \(authorizationValue)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let session = URLSession(configuration: .default)
		let task = session.dataTask(with: request) { responseData, response, responseError in
			guard responseError == nil else {
				completion(.failure(Error.jiraConnection))
				return
			}

			guard let jsonData = responseData else {
				completion(.failure(Error.noDataReceived))
				return
			}

			do {
				var ticket = try JSONDecoder().decode(Ticket.self, from: jsonData)

				guard let epicId = ticket.fields.epicId else {
					completion(.success(ticket))
					return
				}

				self.requestTicket(with: epicId) { result in
					switch result {
					case .success(let epic):
						ticket.fields.epicSummary = epic.fields.summary
					case .failure:
						break
					}

					completion(.success(ticket))
				}
			} catch {
				completion(.failure(Error.ticketParsingError))
			}
		}

		task.resume()
	}
}
