import Foundation
import Git
import GitHub

public struct Payload: Codable {
	public struct Git: Codable {
		public var path: String
		public var shorthand: RepositoryShorthand
		public var defaultBranch: Branch
		public var headBranch: Branch
		public var remote: Remote

		public init(
			path: String,
			shorthand: RepositoryShorthand,
			defaultBranch: Branch,
			headBranch: Branch,
			remote: Remote
		) {
			self.path = path
			self.shorthand = shorthand
			self.defaultBranch = defaultBranch
			self.headBranch = headBranch
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
	public var jira: Jira?

	public init(git: Git, github: GitHub, jira: Jira?) {
		self.git = git
		self.github = github
		self.jira = jira
	}
}

var payload: Payload!

extension Payload {
	public static func path(forRepositoryPath path: String) -> String {
		return FileManager.default.temporaryDirectory.appendingPathComponent("badonde-payload-\(path.sha1()).json").path
	}
}
