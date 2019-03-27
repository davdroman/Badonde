//
//  GitHubMilestoneAPI.swift
//  BadondeCore
//
//  Created by David Roman Aguirre on 27/03/2019.
//

import Foundation

struct GitHubMilestone: Codable {
	let title: String
}

final class GitHubMilestoneAPI: GitHubAPI {
	func fetchAllRepositoryMilestones(withRepositoryShorthand shorthand: String) throws -> [GitHubMilestone] {
		return try fetchRepositoryInfo(
			withRepositoryShorthand: shorthand,
			endpoint: "milestones",
			model: [GitHubMilestone].self,
			queryItems: [URLQueryItem(name: "state", value: "all")]
		)
	}
}
