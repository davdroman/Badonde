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
	}

	private let accessToken: String

	init(accessToken: String) {
		self.accessToken = accessToken
	}

	func fetchRepositoryInfo(withRepositoryShorthand shorthand: String) throws -> GitHubRepositoryInfo {
		let labels = try fetchRepositoryInfo(
			withRepositoryShorthand: shorthand,
			endpoint: "labels",
			model: GitHubRepositoryInfo.Label.self
		)

		let milestones = try fetchRepositoryInfo(
			withRepositoryShorthand: shorthand,
			endpoint: "milestones",
			model: GitHubRepositoryInfo.Milestone.self,
			queryItems: [URLQueryItem(name: "state", value: "all")]
		)

		return GitHubRepositoryInfo(labels: labels, milestones: milestones)
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
			throw Error.urlFormattingError
		}

		let session = URLSession(configuration: .default)
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let response = session.synchronousDataTask(with: request)

		guard response.error == nil else {
			throw Error.githubConnection
		}

		guard let jsonData = response.data else {
			throw Error.noDataReceived
		}

		return try JSONDecoder().decode([EndpointModel].self, from: jsonData)
	}
}

