import Foundation

public struct Issue {
	public var url: URL
	public var number: Int
	public var title: String
	public var body: String?
	public var assignees: [User]
	public var labels: [Label]
	public var milestone: Milestone?
}

extension Issue: Decodable {
	enum CodingKeys: String, CodingKey {
		case url = "html_url"
		case number
		case title
		case body
		case assignees
		case labels
		case milestone
	}
}
