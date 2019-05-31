import Foundation
import Git

extension PullRequest {
	public final class API: GitHub.API {
		public init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func createPullRequest(
			at shorthand: Repository.Shorthand,
			title: String,
			headBranch: String,
			baseBranch: String,
			body: String?,
			isDraft: Bool
		) throws -> PullRequest {
			struct Body: Encodable {
				var title: String
				var head: String
				var base: String
				var body: String?
				var draft: Bool
			}

			return try post(
				endpoint: "/repos/\(shorthand.rawValue)/pulls",
				body: Body(title: title, head: headBranch, base: baseBranch, body: body, draft: isDraft),
				responseType: PullRequest.self
			)
		}
	}
}
