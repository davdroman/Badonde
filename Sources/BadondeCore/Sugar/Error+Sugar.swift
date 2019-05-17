import Foundation
import protocol SwiftCLI.ProcessError

extension Error {
	func analyticsData() -> ErrorAnalyticsReporter.Data {
		return ErrorAnalyticsReporter.Data(
			description: (self as? ProcessError)?.message ?? localizedDescription
		)
	}
}

final class ErrorAnalyticsReporter {
	struct Data: Codable {
		var description: String
	}

	private let firebaseProjectId: String
	private let firebaseSecretToken: String

	init(firebaseProjectId: String, firebaseSecretToken: String) {
		self.firebaseProjectId = firebaseProjectId
		self.firebaseSecretToken = firebaseSecretToken
	}

	func report(_ analyticsData: Data) throws {
		let url = try URL(
			scheme: "https",
			host: "\(firebaseProjectId).firebaseio.com",
			path: "/errors.json",
			queryItems: [URLQueryItem(name: "auth", value: firebaseSecretToken)]
		)

		let session = URLSession(configuration: .default)
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .secondsSince1970
		request.httpBody = try encoder.encode(analyticsData)

		let resultValue = try session.synchronousDataTask(with: request).get()
		let statusCode = (resultValue.response as? HTTPURLResponse)?.statusCode ?? 200

		if 400...599 ~= statusCode {
			throw Error.http(statusCode)
		}
	}
}

extension ErrorAnalyticsReporter {
	enum Error {
		case http(Int)
	}
}

extension ErrorAnalyticsReporter.Error: Swift.Error {
	var localizedDescription: String {
		switch self {
		case .http(let statusCode):
			return "Firebase API call failed with HTTP status code \(statusCode)"
		}
	}
}
