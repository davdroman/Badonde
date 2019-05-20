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

		let resultValue = try session.synchronousDataTask(with: request).get()
		let statusCode = (resultValue.response as? HTTPURLResponse)?.statusCode ?? 200

		let jsonDecoder = JSONDecoder()
		jsonDecoder.dateDecodingStrategy = .iso8601

		switch statusCode {
		case 400...599:
			throw try jsonDecoder.decode(Error.self, from: resultValue.data)
		default:
			return try jsonDecoder.decode(EndpointModel.self, from: resultValue.data)
		}
	}
}

extension API {
	public struct Error {
		var message: String
		var documentationUrl: String?
	}
}

extension API.Error: Codable {
	enum CodingKeys: String, CodingKey {
		case message
		case documentationUrl = "documentation_url"
	}
}

extension API.Error: LocalizedError {
	public var errorDescription: String? {
		let reference = documentationUrl.map { " - refer to \($0)" } ?? ""
		return ["GitHub API call failed with error:", "\(message)" + reference].joined(separator: "\n")
	}
}
