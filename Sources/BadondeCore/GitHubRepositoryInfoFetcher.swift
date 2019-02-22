import Foundation

struct GitHubRepositoryInfo {
	struct Label: Codable {
		let name: String
	}

	struct Milestone: Codable {
		let title: String
	}

	var labels: [Label]
	var milestones: [Milestone]
}

final class GitHubRepositoryInfoFetcher {

	private let accessToken: String

	init(accessToken: String) {
		self.accessToken = accessToken
	}

	func fetchRepositoryInfo(withRepositoryShorthand shorthand: String) throws -> GitHubRepositoryInfo {
		let labels = try fetchAllRepositoryLabels(withRepositoryShorthand: shorthand)
		let milestones = try fetchRepositoryInfo(
			withRepositoryShorthand: shorthand,
			endpoint: "milestones",
			model: GitHubRepositoryInfo.Milestone.self,
			queryItems: [URLQueryItem(name: "state", value: "all")]
		)

		return GitHubRepositoryInfo(labels: labels, milestones: milestones)
	}

	private func fetchAllRepositoryLabels(withRepositoryShorthand shorthand: String) throws -> [GitHubRepositoryInfo.Label] {
		var labels: [GitHubRepositoryInfo.Label] = []
		var currentPage = 1
		while true {
			let newLabels = try fetchRepositoryInfo(
				withRepositoryShorthand: shorthand,
				endpoint: "labels",
				model: GitHubRepositoryInfo.Label.self,
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

	private func fetchRepositoryInfo<EndpointModel: Codable>(
		withRepositoryShorthand shorthand: String,
		endpoint: String,
		model: EndpointModel.Type,
		queryItems: [URLQueryItem]? = nil
	) throws -> [EndpointModel] {
		let labelsUrl = URL(
			scheme: "https",
			host: "api.github.com",
			path: "/repos/\(shorthand)/\(endpoint)",
			queryItems: queryItems
		)

		guard let url = labelsUrl else {
			throw Error.invalidEndpointURLFormat(model)
		}

		let session = URLSession(configuration: .default)
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let response = session.synchronousDataTask(with: request)

		if let error = response.error {
			throw Error.githubConnectionFailed(error)
		}

		guard let jsonData = response.data else {
			throw Error.noDataReceived(model)
		}

		return try JSONDecoder().decode([EndpointModel].self, from: jsonData)
	}
}

