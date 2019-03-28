import Foundation

extension Milestone {
	public final class API: GitHub.API {
		public func getMilestones(for shorthand: Repository.Shorthand) throws -> [Milestone] {
			return try get(
				[Milestone].self,
				for: shorthand,
				endpoint: "milestones",
				queryItems: [URLQueryItem(name: "state", value: "all")]
			)
		}
	}
}
