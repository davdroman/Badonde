import Foundation

struct TicketId: Codable {
	let prefix: String
	let number: String
	var rawValue: String {
		return [prefix, number].joined(separator: "-")
	}

	init?(rawValue: String) {
		let components = rawValue.split(separator: "-")
		guard
			let prefix = components[safe: 0],
			let number = components[safe: 1]
		else {
			return nil
		}
		self.init(prefix: String(prefix), number: String(number))
	}

	init(prefix: String, number: String) {
		self.prefix = prefix
		self.number = number
	}

	init(from decoder: Decoder) throws {
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

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}

struct Ticket: Codable {
	let key: String
	var fields: TicketFields
}

struct TicketFields: Codable {
	let fixVersions: [FixVersion]
	let issueType: IssueType
	let summary: String
	let epicId: TicketId?
	var epicSummary: String?

	enum CodingKeys: String, CodingKey {
		case fixVersions = "fixVersions"
		case issueType = "issuetype"
		case summary = "summary"
		case epicId = "customfield_10008"
	}
}

struct FixVersion: Codable {
	let fixVersionSelf: String
	let id: String
	let name: String
	let archived: Bool
	let released: Bool

	enum CodingKeys: String, CodingKey {
		case fixVersionSelf = "self"
		case id = "id"
		case name = "name"
		case archived = "archived"
		case released = "released"
	}
}

struct IssueType: Codable {
	let issuetypeSelf: String
	let id: String
	let description: String
	let iconURL: String
	let name: String
	let subtask: Bool
	let avatarID: Int

	enum CodingKeys: String, CodingKey {
		case issuetypeSelf = "self"
		case id = "id"
		case description = "description"
		case iconURL = "iconUrl"
		case name = "name"
		case subtask = "subtask"
		case avatarID = "avatarId"
	}
}
