import Foundation
import Git

extension Milestone {
	public final class API: GitHub.API {
		public init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func getMilestones(for shorthand: Repository.Shorthand) throws -> [Milestone] {
			return try get(
				endpoint: "/repos/\(shorthand)/milestones",
				queryItems: [URLQueryItem(name: "state", value: "open")],
				responseType: [Milestone].self
			)
		}
	}
}
