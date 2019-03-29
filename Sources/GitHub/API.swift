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
		// TODO: change deployment target to 10.12 when upgrading to Swift 5
		// https://github.com/apple/swift-evolution/blob/master/proposals/0236-package-manager-platform-deployment-settings.md
		if #available(OSX 10.12, *) {
			jsonDecoder.dateDecodingStrategy = .iso8601
		} else {
			let formatter = DateFormatter()
			formatter.calendar = Calendar(identifier: .iso8601)
			formatter.locale = Locale(identifier: "en_US_POSIX")
			formatter.timeZone = TimeZone(secondsFromGMT: 0)

			jsonDecoder.dateDecodingStrategy = .custom { decoder -> Date in
				let container = try decoder.singleValueContainer()
				let dateStr = try container.decode(String.self)

				formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
				if let date = formatter.date(from: dateStr) {
					return date
				}
				formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
				if let date = formatter.date(from: dateStr) {
					return date
				}
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "Invalid ISO-8601 format on value \(dateStr)"
				)
			}
		}

		switch httpResponse.statusCode {
		case 400...599:
			throw try jsonDecoder.decode(Error.self, from: jsonData)
		default:
			return try jsonDecoder.decode(EndpointModel.self, from: jsonData)
		}
	}
}
