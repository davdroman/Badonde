import Foundation
import Sugar

open class API {
	private let accessToken: String

	public init(accessToken: String) {
		self.accessToken = accessToken
	}

	func get<EndpointModel: Codable>(
		_ model: EndpointModel.Type,
		for shorthand: Repository.Shorthand,
		endpoint: String?,
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
			throw error
		}

		guard let httpResponse = response.response as? HTTPURLResponse, let jsonData = response.data else {
			fatalError("Impossible!") // TODO: fix through use of Result in Swift 5 🤩 https://github.com/apple/swift-evolution/blob/master/proposals/0235-add-result.md
		}

		let jsonDecoder = JSONDecoder()
		jsonDecoder.dateDecodingStrategy = .iso8601

		switch httpResponse.statusCode {
		case 400...599:
			throw try jsonDecoder.decode(Error.self, from: jsonData)
		default:
			return try jsonDecoder.decode(EndpointModel.self, from: jsonData)
		}
	}
}
