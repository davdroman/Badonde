//
//  GitHubReleaseAPI.swift
//  BadondeCore
//
//  Created by David Roman Aguirre on 26/03/2019.
//

import Foundation
import SwiftCLI

final class GitHubReleaseAPI: GitHubAPI {
	func fetchAllReleases(withRepositoryShorthand shorthand: String) throws -> [GitHubRelease] {
		return try fetchRepositoryInfo(
			withRepositoryShorthand: shorthand,
			endpoint: "releases",
			model: [GitHubRelease].self
		)
	}
}
