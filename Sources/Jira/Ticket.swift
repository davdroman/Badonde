import Foundation
import Sugar

public struct Ticket: Codable {
	public let key: Key
	public var fields: Fields
}

extension Ticket {
	public struct Key: Codable, CustomStringConvertible {
		let prefix: String
		let number: String
		public var rawValue: String {
			return [prefix, number].joined(separator: "-")
		}

		public init?(rawValue: String) {
			let components = rawValue.split(separator: "-")
			guard
				let prefix = components[safe: 0],
				let number = components[safe: 1]
				else {
					return nil
			}
			self.init(prefix: String(prefix), number: String(number))
		}

		public init(prefix: String, number: String) {
			self.prefix = prefix
			self.number = number
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			let ticketId = try container.decode(String.self)
			guard let _self = type(of: self).init(rawValue: ticketId) else {
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "Ticket ID could not be parsed"
				)
			}
			self = _self
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(rawValue)
		}

		public var description: String {
			return rawValue
		}
	}
}

extension Ticket {
	public struct Fields: Codable {
		public let fixVersions: [FixVersion]
		public let issueType: IssueType
		public let summary: String
		public let epicKey: Key?
		public var epicSummary: String?
		public let parentTicket: ParentTicket?

		enum CodingKeys: String, CodingKey {
			case fixVersions = "fixVersions"
			case issueType = "issuetype"
			case summary = "summary"
			case epicKey = "customfield_10008"
			case parentTicket = "parent"
		}
	}
}

extension Ticket.Fields {
	public struct FixVersion: Codable {
		public let name: String

		enum CodingKeys: String, CodingKey {
			case name = "name"
		}
	}
}

extension Ticket.Fields {
	public struct IssueType: Codable {
		public let name: String
		public let isSubtask: Bool

		enum CodingKeys: String, CodingKey {
			case name = "name"
			case isSubtask = "subtask"
		}
	}
}

extension Ticket.Fields {
	public struct ParentTicket: Codable {
		public let key: Ticket.Key
	}
}
