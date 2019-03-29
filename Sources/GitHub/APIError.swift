import Foundation

extension API {
	public struct Error {
		var message: String
		var documentationUrl: String?
	}
}

extension API.Error: Codable {
	enum CodingKeys: String, CodingKey {
		case message
		case documentationUrl = "documentation_url"
	}
}

extension API.Error: Swift.Error {
	public var localizedDescription: String {
		let reference = documentationUrl.map { " - refer to \($0)" } ?? ""
		return "GitHub API call failed with error: \(message)" + reference
	}
}
