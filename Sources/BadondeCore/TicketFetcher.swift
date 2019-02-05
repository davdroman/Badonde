//
//  TicketFetcher.swift
//  BadondeCore
//
//  Created by David Roman on 04/02/2019.
//

import Foundation
import JIRAKit
import Result

fileprivate struct TicketId {
	let prefix: String
	let number: String
	var value: String {
		return [prefix, number].joined(separator: "-")
	}

	init(prefix: String, number: String) {
		self.prefix = prefix
		self.number = number
	}

	init?(branchName: String) {
		guard
			let ticketComponents = branchName.split(separator: "_").first?.split(separator: "-").prefix(2),
			let ticketPrefix = ticketComponents[safe: 0],
			let ticketNumber = ticketComponents[safe: 1]
		else {
			return nil
		}
		self.init(prefix: String(ticketPrefix), number: String(ticketNumber))
	}
}

final class TicketFetcher {

	enum Error: Swift.Error {
		case invalidBranchFormat
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
		fromBranchName branchName: String,
		completion: @escaping (Result<Ticket, Error>) -> Void
	) {
		guard let ticketId = TicketId(branchName: branchName) else {
			completion(.failure(Error.invalidBranchFormat))
			return
		}

		guard ticketId.value != "NO-TICKET" else {
			completion(.failure(Error.noTicket))
			return
		}

		requestTicket(withTicketId: ticketId.value, expanded: true) { result in
			completion(result)
		}
	}

	private func requestTicket(
		withTicketId ticketId: String,
		expanded: Bool = false,
		completion: @escaping (Result<Ticket, Error>) -> Void
	) {
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = "asosmobile.atlassian.net"
		urlComponents.path = "/rest/api/2/issue/\(ticketId)"
		if expanded {
			urlComponents.queryItems = [URLQueryItem.init(name: "expand", value: "names")]
		}

		guard let jiraUrl = urlComponents.url else {
			completion(.failure(Error.urlFormattingError))
			return
		}

		guard let authorizationValue = authorizationValue else {
			completion(.failure(Error.authorizationEncodingError))
			return
		}

		var request = URLRequest(url: jiraUrl)
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

				guard let epicKey = ticket.fields.epicKey else {
					completion(.success(ticket))
					return
				}

				self.requestTicket(withTicketId: epicKey) { result in
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
