import Foundation

public struct Release: Codable {
	public struct Asset: Codable {
		public var downloadUrl: URL

		private enum CodingKeys: String, CodingKey {
			case downloadUrl = "browser_download_url"
		}
	}

	public var version: String
	public var date: Date
	public var assets: [Asset]

	private enum CodingKeys: String, CodingKey {
		case version = "tag_name"
		case date = "published_at"
		case assets
	}
}
