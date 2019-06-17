import Foundation
import Sugar

extension API {
	public enum Error: LocalizedError {
		case http(response: HTTPURLResponse, githubError: GitHubError?)

		public var errorDescription: String? {
			switch self {
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
