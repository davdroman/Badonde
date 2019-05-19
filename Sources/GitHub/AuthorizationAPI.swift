import Foundation
import Sugar

extension Authorization {
	public final class API {
		enum Constant {
			static let githubOTPHeaderKey = "X-GitHub-OTP"
		}

		let username: String
		let password: String
		var authorizationValue: String? {
			let rawString = [username, password].joined(separator: ":")
			guard let utf8StringRepresentation = rawString.data(using: .utf8) else {
				return nil
			}
			return utf8StringRepresentation.base64EncodedString()
		}

		public init(username: String, password: String) {
			self.username = username
			self.password = password
		}

		struct CreateAuthorizationBody: Codable {
			var scopes: [Scope]
			var note: String
		}

		public func createAuthorization(scopes: [Scope], note: String, oneTimePassword: @autoclosure () -> String) throws -> Authorization {
			let url = try URL(
				scheme: "https",
				host: "api.github.com",
				path: "/authorizations"
			)

			guard let authorizationValue = authorizationValue else {
				throw Error.authorizationEncodingError
			}

			let session = URLSession(configuration: .default)
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.setValue("Basic \(authorizationValue)", forHTTPHeaderField: "Authorization")
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")

			var currentNoteSuffixIndex = 1
			while true {
				let noteSuffix = currentNoteSuffixIndex > 1 ? " \(currentNoteSuffixIndex)" : ""
				let body = CreateAuthorizationBody(scopes: scopes, note: note + noteSuffix)
				request.httpBody = try JSONEncoder().encode(body)

				let resultValue = try session.synchronousDataTask(with: request).get()
				guard let httpResponse = resultValue.response as? HTTPURLResponse else {
					fatalError("Response should always be a HTTPURLResponse for scheme 'https'")
				}

				switch httpResponse.statusCode {
				case 422: // already exists
					currentNoteSuffixIndex += 1
					continue
				case 401: // OTP required
					guard
						let githubOTPHeaderValue = httpResponse.allHeaderFields[Constant.githubOTPHeaderKey] as? String,
						githubOTPHeaderValue.hasPrefix("required")
					else {
						fallthrough
					}
					request.setValue(oneTimePassword(), forHTTPHeaderField: Constant.githubOTPHeaderKey)
					continue
				case 400...599:
					let error = try JSONDecoder().decode(GitHub.API.Error.self, from: resultValue.data)
					throw Error.github(error)
				default:
					return try JSONDecoder().decode(Authorization.self, from: resultValue.data)
				}
			}
		}
	}
}

extension Authorization.API {
	public enum Error {
		case authorizationEncodingError
		case github(GitHub.API.Error)
	}
}

extension Authorization.API.Error: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .authorizationEncodingError:
			return "GitHub authorization token encoding failed"
		case .github(let error):
			return error.errorDescription
		}
	}
}
