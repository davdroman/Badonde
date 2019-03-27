import Foundation

struct GitHubLabel: Codable {
	let name: String
}

final class GitHubLabelAPI: GitHubAPI {
	func fetchAllRepositoryLabels(withRepositoryShorthand shorthand: String) throws -> [GitHubLabel] {
		var labels: [GitHubLabel] = []
		var currentPage = 1
		while true {
			let newLabels = try fetchRepositoryInfo(
				withRepositoryShorthand: shorthand,
				endpoint: "labels",
				model: [GitHubLabel].self,
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

