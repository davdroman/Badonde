//
//  GitHubRepositoryInfoFetcher.swift
//  BadondeCore
//
//  Created by David Roman on 06/02/2019.
//

import Foundation
import Result

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

	enum Error: Swift.Error {
		case urlFormattingError
		case githubConnection
		case noDataReceived
		case infoParsingError
	}

	private let accessToken: String

	init(accessToken: String) {
		self.accessToken = accessToken
	}

	func fetchRepositoryInfo(
		withRepositoryShorthand shorthand: String,
		completion: @escaping (Result<GitHubRepositoryInfo, Error>) -> Void
	) {
		let labelFetchingCompletion: ([GitHubRepositoryInfo.Label]) -> Void = { labels in
			self.fetchRepositoryInfo(
				withRepositoryShorthand: shorthand,
				endpoint: "milestones",
				model: GitHubRepositoryInfo.Milestone.self,
				queryItems: [URLQueryItem(name: "state", value: "all")],
				completion: { result in
					switch result {
					case .success(let milestones):
						let repoInfo = GitHubRepositoryInfo(labels: labels, milestones: milestones)
						completion(.success(repoInfo))
					case .failure(let error):
						completion(.failure(error))
					}
				}
			)
		}

		var allLabels: [GitHubRepositoryInfo.Label] = []

		let fetchAllRepositoryLabelsForPageClosure: (Int) -> Void = { page in
			self.fetchRepositoryLabels(forPage: page, completion: { result in in

			})
		}
	}

	func fetchRepositoryLabels(
		forPage page: Int,
		completion: @escaping (Result<[GitHubRepositoryInfo.Label], Error>) -> Void
	) {
		self.fetchRepositoryInfo(
			withRepositoryShorthand: shorthand,
			endpoint: "labels",
			model: GitHubRepositoryInfo.Label.self,
			queryItems: [URLQueryItem.init(name: "page", value: "\(page)")],
			completion: {
				switch result {
				case .success(let labels):
					guard labels.isEmpty else {
						completion(allLabels)
						return
					}
					allLabels += labels
					self.fetchRepositoryLabels(forPage: page + 1, completion: completion)
				case .failure(let error):
					completion(.failure(error))
				}
			}
		)
	}

	private func fetchRepositoryInfo<EndpointModel: Codable>(
		withRepositoryShorthand shorthand: String,
		endpoint: String,
		model: EndpointModel.Type,
		queryItems: [URLQueryItem]? = nil
	) -> Result<[EndpointModel], Error> {
		let labelsUrl = URL(
			scheme: "https",
			host: "api.github.com",
			path: "/repos/\(shorthand)/\(endpoint)",
			queryItems: queryItems
		)

		guard let url = labelsUrl else {
			return .failure(Error.urlFormattingError)
		}

		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let session = URLSession(configuration: .default)
		let response = session.synchronousDataTask(with: request)
		guard response.error == nil else {
			return .failure(Error.githubConnection)

		}

		guard let jsonData = response.data else {
			return .failure(Error.noDataReceived)
		}

		do {
			let endpointValues = try JSONDecoder().decode([EndpointModel].self, from: jsonData)
			return .success(endpointValues)
		} catch {
			return .failure(Error.infoParsingError)
		}
	}
}
