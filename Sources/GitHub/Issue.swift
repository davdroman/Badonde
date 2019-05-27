import Foundation

public struct Issue {
	public var url: URL
	public var number: Int
}

extension Issue: Decodable {
	enum CodingKeys: String, CodingKey {
		case url = "html_url"
		case number
	}
}
