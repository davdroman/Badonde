import Foundation

struct Ticket: Codable {
	let key: String
	var fields: TicketFields
}

struct TicketFields: Codable {
	let fixVersions: [FixVersion]
	let issueType: IssueType
	let summary: String
	let epicKey: String?
	var epicSummary: String?

	enum CodingKeys: String, CodingKey {
		case fixVersions = "fixVersions"
		case issueType = "issuetype"
		case summary = "summary"
		case epicKey = "customfield_10008"
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
