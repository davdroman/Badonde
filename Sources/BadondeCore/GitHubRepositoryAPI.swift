//
//  GitHubRepositoryAPI.swift
//  BadondeCore
//
//  Created by David Roman Aguirre on 27/03/2019.
//

import Foundation

struct GitHubRepository: Codable {
	let defaultBranch: String

	private enum CodingKeys: String, CodingKey {
		case defaultBranch = "default_branch"
	}
}

final class GitHubRepositoryAPI: GitHubAPI {
	func fetchRepository(withRepositoryShorthand shorthand: String) throws -> GitHubRepository {
		return try fetchRepositoryInfo(
			withRepositoryShorthand: shorthand,
			endpoint: nil,
			model: GitHubRepository.self
		)
	}
}
