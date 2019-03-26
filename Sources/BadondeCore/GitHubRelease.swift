//
//  GitHubRelease.swift
//  BadondeCore
//
//  Created by David Roman Aguirre on 26/03/2019.
//

import Foundation

struct GitHubRelease: Codable {
	struct Asset: Codable {
		var downloadUrl: URL

		private enum CodingKeys: String, CodingKey {
			case downloadUrl = "browser_download_url"
		}
	}

	var date: Date
	var assets: [Asset]

	private enum CodingKeys: String, CodingKey {
		case date = "published_at"
		case assets
	}
}
