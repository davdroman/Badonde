import Foundation

public struct Release: Decodable {
	public struct Asset: Decodable {
		public var downloadUrl: URL

		private enum CodingKeys: String, CodingKey {
			case downloadUrl = "browser_download_url"
		}
	}

	private enum CodingKeys: String, CodingKey {
		case version = "tag_name"
		case date = "published_at"
		case assets
	}

	public var version: String
	public var date: Date
	public var assets: [Asset]
}
