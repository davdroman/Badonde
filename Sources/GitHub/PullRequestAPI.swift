import Foundation
import Git

extension PullRequest {
	public final class API: GitHub.API {
		public enum State: String {
			case open
			case closed
			case all
		}

		public enum Sorting: String {
			public enum Direction: String {
				case ascendent = "asc"
				case descendent = "desc"
			}

			case created
			case updated
			case popularity
			case longRunning = "long-running"
		}

		public init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func allPullRequests(
			for shorthand: Repository.Shorthand,
			state: State? = nil,
			headBranch: String? = nil,
			baseBranch: String? = nil,
			sortedBy: Sorting? = nil,
			_ direction: Sorting.Direction? = nil
		) throws -> [PullRequest] {
			var pullRequests: [PullRequest] = []
			var currentPage = 1
			let resultsPerPage = 100
			while true {
				let newPullRequests = try self.pullRequests(
					for: shorthand,
					page: currentPage,
					perPage: resultsPerPage,
					state: state,
					headBranch: headBranch,
					baseBranch: baseBranch,
					sortedBy: sortedBy,
					direction
				)
				pullRequests += newPullRequests
				guard newPullRequests.count == resultsPerPage else {
					break
				}
				currentPage += 1
			}
			return pullRequests
		}

		public func pullRequests(
			for shorthand: Repository.Shorthand,
			page: Int? = nil,
			perPage: Int? = nil,
			state: State? = nil,
			headBranch: String? = nil,
			baseBranch: String? = nil,
			sortedBy: Sorting? = nil,
			_ direction: Sorting.Direction? = nil
		) throws -> [PullRequest] {
			return try get(
				endpoint: "/repos/\(shorthand.rawValue)/pulls",
				queryItems: [
					URLQueryItem(name: "page", mandatoryValue: page.map(String.init)),
					URLQueryItem(name: "per_page", mandatoryValue: perPage.map(String.init)),
					URLQueryItem(name: "state", mandatoryValue: state?.rawValue),
					URLQueryItem(name: "head", mandatoryValue: headBranch),
					URLQueryItem(name: "base", mandatoryValue: baseBranch),
					URLQueryItem(name: "sort", mandatoryValue: sortedBy?.rawValue),
					URLQueryItem(name: "direction", mandatoryValue: direction?.rawValue),
				].compacted(),
				responseType: [PullRequest].self
			)
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
