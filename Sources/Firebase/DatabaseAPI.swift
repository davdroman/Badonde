import Foundation
import Sugar

public final class DatabaseAPI {
	let firebaseProjectId: String
	let firebaseSecretToken: String

	public init(firebaseProjectId: String, firebaseSecretToken: String) {
		self.firebaseProjectId = firebaseProjectId
		self.firebaseSecretToken = firebaseSecretToken
	}

	public func post<T: Encodable>(documentName: String, body: T) throws {
		let url = try URL(
			scheme: "https",
			host: "\(firebaseProjectId).firebaseio.com",
			path: "/\(documentName).json",
			queryItems: [URLQueryItem(name: "auth", value: firebaseSecretToken)]
		)

		let session = URLSession(configuration: .default)
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .secondsSince1970
		request.httpBody = try encoder.encode(body)

		let resultValue = try session.synchronousDataTask(with: request).get()
		let statusCode = (resultValue.response as? HTTPURLResponse)?.statusCode ?? 200

		if 400...599 ~= statusCode {
			throw Error.http(statusCode)
		}
	}
}

extension DatabaseAPI {
	enum Error {
		case http(Int)
	}
}

extension DatabaseAPI.Error: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .http(let statusCode):
			return "Firebase API call failed with HTTP status code \(statusCode)"
		}
	}
}
