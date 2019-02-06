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
		fetchRepositoryInfo(
			withRepositoryShorthand: shorthand,
			endpoint: "labels",
			model: GitHubRepositoryInfo.Label.self,
			completion: { result in
				switch result {
				case .success(let labels):
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
		queryItems: [URLQueryItem]? = nil,
		completion: @escaping (Result<[EndpointModel], Error>) -> Void
	) {
		let labelsUrl = URL(
			scheme: "https",
			host: "api.github.com",
			path: "/repos/\(shorthand)/\(endpoint)",
			queryItems: queryItems
		)

		guard let url = labelsUrl else {
			completion(.failure(Error.urlFormattingError))
			return
		}

		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let session = URLSession(configuration: .default)
		let task = session.dataTask(with: request) { responseData, response, responseError in
			guard responseError == nil else {
				completion(.failure(Error.githubConnection))
				return
			}

			guard let jsonData = responseData else {
				completion(.failure(Error.noDataReceived))
				return
			}

			do {
				let endpointValues = try JSONDecoder().decode([EndpointModel].self, from: jsonData)
				completion(.success(endpointValues))
			} catch {
				completion(.failure(Error.infoParsingError))
			}
		}

		task.resume()
	}
}

