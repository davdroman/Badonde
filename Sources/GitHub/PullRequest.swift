import Foundation

public class PullRequest: Decodable {
	public var url: URL
	public var number: Int

	enum CodingKeys: String, CodingKey {
		case url = "html_url"
		case number
	}
}
