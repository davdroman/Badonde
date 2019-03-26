//
//  GitHubAPI.swift
//  BadondeCore
//
//  Created by David Roman Aguirre on 26/03/2019.
//

import Foundation

open class GitHubAPI {
	private let accessToken: String

	init(accessToken: String) {
		self.accessToken = accessToken
	}

	func fetchRepositoryInfo<EndpointModel: Codable>(
		withRepositoryShorthand shorthand: String,
		endpoint: String?,
		model: EndpointModel.Type,
		queryItems: [URLQueryItem]? = nil
	) throws -> EndpointModel {
		let endpoint = endpoint.map { "/\($0)" } ?? ""
		let url = try URL(
			scheme: "https",
			host: "api.github.com",
			path: "/repos/\(shorthand)\(endpoint)",
			queryItems: queryItems
		)

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

		let jsonDecoder = JSONDecoder()
		if #available(OSX 10.12, *) {
			jsonDecoder.dateDecodingStrategy = .iso8601
		} else {
			// Fallback on earlier versions
		}
		return try jsonDecoder.decode(EndpointModel.self, from: jsonData)
	}
}
