//
//  GitHubRepositoryInfoFetcher.swift
//  BadondeCore
//
//  Created by David Roman on 06/02/2019.
//

import Foundation
import Result

struct GitHubRepositoryInfo {
	var labels: [GitHubRepositoryLabel]
}

struct GitHubRepositoryLabel: Codable {
	let id: Int
	let nodeID: String
	let url: String
	let name: String
	let description: String
	let color: String
	let labelDefault: Bool

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case nodeID = "node_id"
		case url = "url"
		case name = "name"
		case description = "description"
		case color = "color"
		case labelDefault = "default"
	}
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
		let labelsUrl = URL(
			scheme: "https",
			host: "api.github.com",
			path: "/repos/\(shorthand)/labels"
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
				let labels = try JSONDecoder().decode([GitHubRepositoryLabel].self, from: jsonData)
				let repoInfo = GitHubRepositoryInfo(labels: labels)

				completion(.success(repoInfo))
			} catch {
				completion(.failure(Error.infoParsingError))
			}
		}

		task.resume()
	}
}

