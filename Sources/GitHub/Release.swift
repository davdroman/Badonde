import Foundation

public struct Release: Codable {
	public struct Asset: Codable {
		public var downloadUrl: URL

		private enum CodingKeys: String, CodingKey {
			case downloadUrl = "browser_download_url"
		}
	}

	public var date: Date
	public var assets: [Asset]

	private enum CodingKeys: String, CodingKey {
		case date = "published_at"
		case assets
	}
}
