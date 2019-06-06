import Foundation
import Git

public struct Payload: Codable {
	public struct Configuration: Codable {
		public struct Git: Codable {
			public var remote: Remote

			public init(remote: Remote) {
				self.remote = remote
			}
		}

		public struct GitHub: Codable {
			public var accessToken: String

			public init(accessToken: String) {
				self.accessToken = accessToken
			}
		}

		public struct Jira: Codable {
			public var email: String
			public var apiToken: String

			public init(email: String, apiToken: String) {
				self.email = email
				self.apiToken = apiToken
			}
		}

		public var git: Git
		public var github: GitHub
		public var jira: Jira

		public init(git: Git, github: GitHub, jira: Jira) {
			self.git = git
			self.github = github
			self.jira = jira
		}
	}

	public var configuration: Configuration

	public init(configuration: Configuration) {
		self.configuration = configuration
	}
}

extension Payload {
	public static func path(forRepositoryAt url: URL) -> URL {
		return FileManager.default.temporaryDirectory.appendingPathComponent("badonde-payload-\(url.path.sha1()).json")
	}
}
