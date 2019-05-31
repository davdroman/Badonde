import Foundation
import Git

extension Issue {
	public final class API: GitHub.API {
		public init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func edit(
			at shorthand: Repository.Shorthand,
			issueNumber: Int,
			title: String? = nil,
			body: String? = nil,
			assignees: [String]? = nil,
			labels: [String]? = nil,
			milestone: Int? = nil
		) throws -> Issue {
			struct Body: Encodable {
				var title: String?
				var body: String?
				var assignees: [String]?
				var labels: [String]?
				var milestone: Int?
			}

			return try patch(
				endpoint: "/repos/\(shorthand.rawValue)/issues/\(issueNumber)",
				body: Body(title: title, body: body, assignees: assignees, labels: labels, milestone: milestone),
				responseType: Issue.self
			)
		}
	}
}
