import Foundation

open class API {
	typealias HTTPHeader = (field: String, value: String?)

	let authorization: Authorization

	init(authorization: Authorization) {
		self.authorization = authorization
	}

	func get<ResponseModel: Decodable>(
		endpoint: String?,
		queryItems: [URLQueryItem]? = nil,
		headers: [HTTPHeader] = [],
		responseType: ResponseModel.Type
	) throws -> ResponseModel {
		return try perform("GET", endpoint: endpoint, queryItems: queryItems, headers: headers, body: nil, responseType: responseType)
	}

	func post<RequestModel: Encodable, ResponseModel: Decodable>(
		endpoint: String?,
		queryItems: [URLQueryItem]? = nil,
		headers: [HTTPHeader] = [],
		body: RequestModel,
		responseType: ResponseModel.Type
	) throws -> ResponseModel {
		return try perform("POST", endpoint: endpoint, queryItems: queryItems, headers: headers, body: JSONEncoder().encode(body), responseType: responseType)
	}

	func patch<RequestModel: Encodable, ResponseModel: Decodable>(
		endpoint: String?,
		queryItems: [URLQueryItem]? = nil,
		headers: [HTTPHeader] = [],
		body: RequestModel,
		responseType: ResponseModel.Type
	) throws -> ResponseModel {
		return try perform("PATCH", endpoint: endpoint, queryItems: queryItems, headers: headers, body: JSONEncoder().encode(body), responseType: responseType)
	}

	private func perform<ResponseModel: Decodable>(
		_ method: String,
		endpoint: String?,
		queryItems: [URLQueryItem]?,
		headers: [HTTPHeader],
		body: Data?,
		responseType: ResponseModel.Type
	) throws -> ResponseModel {
		let url = try URL(
			scheme: "https",
			host: "api.github.com",
			path: endpoint ?? "/",
			queryItems: queryItems
		)

		let session = URLSession(configuration: .default)
		var request = URLRequest(url: url)
		request.httpMethod = method
		request.setValue(try authorization.headerValue(), forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.addValue("application/vnd.github.shadow-cat-preview+json", forHTTPHeaderField: "Accept")
		request.addValue("application/vnd.github.symmetra-preview+json", forHTTPHeaderField: "Accept")
		headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.field) }
		request.httpBody = body

		let resultValue = try session.synchronousDataTask(with: request).get()
		guard let response = resultValue.response as? HTTPURLResponse else {
			fatalError("Response should always be a HTTPURLResponse for scheme 'https'")
		}

		let jsonDecoder = JSONDecoder()
		jsonDecoder.dateDecodingStrategy = .iso8601

		switch response.statusCode {
		case 400...599:
			let githubError = try? jsonDecoder.decode(GitHubError.self, from: resultValue.data)
			throw Error.http(response: response, githubError: githubError)
		default:
			return try jsonDecoder.decode(ResponseModel.self, from: resultValue.data)
		}
	}
}

extension API {
	public enum Authorization {
		case unauthenticated
		case token(String)
		case basic(username: String, password: String)

		func headerValue() throws -> String? {
			switch self {
			case .unauthenticated:
				return nil
			case let .token(token):
				return ["token", token].joined(separator: " ")
			case let .basic(username, password):
				let token = [username, password].joined(separator: ":").base64()
				return ["Basic", token].joined(separator: " ")
			}
		}
	}
}
