import Foundation

private struct GitHubRepository: Codable {
	let defaultBranch: String

	private enum CodingKeys: String, CodingKey {
		case defaultBranch = "default_branch"
	}
}

struct GitHubRepositoryInfo {
	struct Label: Codable {
		let name: String
	}

	struct Milestone: Codable {
		let title: String
	}

	var defaultBranch: String
	var labels: [Label]
	var milestones: [Milestone]
}

final class GitHubRepositoryInfoFetcher: GitHubAPI {
	func fetchRepositoryInfo(withRepositoryShorthand shorthand: String) throws -> GitHubRepositoryInfo {
		let repository = try fetchRepository(withRepositoryShorthand: shorthand)
		let labels = try fetchAllRepositoryLabels(withRepositoryShorthand: shorthand)
		let milestones = try fetchRepositoryInfo(
			withRepositoryShorthand: shorthand,
			endpoint: "milestones",
			model: [GitHubRepositoryInfo.Milestone].self,
			queryItems: [URLQueryItem(name: "state", value: "all")]
		)

		return GitHubRepositoryInfo(
			defaultBranch: repository.defaultBranch,
			labels: labels,
			milestones: milestones
		)
	}

	private func fetchRepository(withRepositoryShorthand shorthand: String) throws -> GitHubRepository {
		return try fetchRepositoryInfo(
			withRepositoryShorthand: shorthand,
			endpoint: nil,
			model: GitHubRepository.self
		)
	}

	private func fetchAllRepositoryLabels(withRepositoryShorthand shorthand: String) throws -> [GitHubRepositoryInfo.Label] {
		var labels: [GitHubRepositoryInfo.Label] = []
		var currentPage = 1
		while true {
			let newLabels = try fetchRepositoryInfo(
				withRepositoryShorthand: shorthand,
				endpoint: "labels",
				model: [GitHubRepositoryInfo.Label].self,
				queryItems: [URLQueryItem(name: "page", value: "\(currentPage)")]
			)
			guard !newLabels.isEmpty else {
				break
			}
			labels += newLabels
			currentPage += 1
		}
		return labels
	}
}

