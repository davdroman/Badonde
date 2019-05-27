import Foundation
import Sugar

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
				let rawString = [username, password].joined(separator: ":")
				guard let utf8StringRepresentation = rawString.data(using: .utf8) else {
					throw Error.authorizationEncodingError
				}
				let token = utf8StringRepresentation.base64EncodedString()
				return ["Basic", token].joined(separator: " ")
			}
		}
	}
}

extension API {
	public enum Error: LocalizedError {
		case authorizationEncodingError
		case http(response: HTTPURLResponse, githubError: GitHubError?)

		public var errorDescription: String? {
			switch self {
			case .authorizationEncodingError:
				return "GitHub authorization token encoding failed"
			case let .http(response, githubError):
				return [
					"GitHub API call failed with HTTP status code \(response.statusCode)",
					githubError?.errorDescription
				].compacted().joined(separator: "\n")
			}
		}
	}
}

extension API {
	public struct GitHubError: LocalizedError {
		public var message: String
		public var details: [Detail]?
		public var documentationURL: String?

		public var errorDescription: String? {
			let details = self.details?.map { $0.description }.joined(separator: "\n")
			let reference = documentationURL.map { "Refer to \($0)" }
			return [message, details, reference].compacted().joined(separator: "\n")
		}
	}
}

extension API.GitHubError: Decodable {
	enum CodingKeys: String, CodingKey {
		case message
		case details = "errors"
		case documentationURL = "documentation_url"
	}
}

extension API.GitHubError {
	public struct Detail: Decodable, CustomStringConvertible {
		public var resource: String
		public var field: String?
		public var code: String

		public var description: String {
			let fieldDescription = field.map { "on field \($0)" }
			return ["\(resource) failure with code '\(code)'", fieldDescription].compacted().joined(separator: " ")
		}
	}
}
