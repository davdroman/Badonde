import Foundation

extension Issue {
	public final class API: GitHub.API {
		init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func edit(
			at shorthand: Repository.Shorthand,
			issueNumber: Int,
			title: String?,
			body: String?,
			assignees: [String]?,
			labels: [String]?,
			milestone: Int?
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
