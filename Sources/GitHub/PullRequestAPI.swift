import Foundation

extension PullRequest {
	public final class API: GitHub.API {
		init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func createPullRequest(
			at shorthand: Repository.Shorthand,
			title: String,
			headBranch: String,
			baseBranch: String,
			body: String,
			isDraft: Bool
		) throws -> PullRequest {
			struct Body: Encodable {
				var title: String
				var head: String
				var base: String
				var body: String
				var draft: Bool
			}

			return try post(
				endpoint: "/repos/\(shorthand.rawValue)/pulls",
				body: Body(title: title, head: headBranch, base: baseBranch, body: body, draft: isDraft),
				responseType: PullRequest.self
			)
		}

		public func requestReviewers(at shorthand: Repository.Shorthand, pullRequestNumber: Int, reviewers: [String]) throws -> PullRequest {
			struct Body: Encodable {
				var reviewers: [String]
			}

			return try post(
				endpoint: "/repos/\(shorthand.rawValue)/pulls/\(pullRequestNumber)/requested_reviewers",
				body: Body(reviewers: reviewers),
				responseType: PullRequest.self
			)
		}
	}
}
