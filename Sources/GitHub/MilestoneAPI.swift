import Foundation

extension Milestone {
	public final class API: GitHub.API {
		public func fetchAllRepositoryMilestones(for shorthand: Repository.Shorthand) throws -> [Milestone] {
			return try fetchRepositoryInfo(
				for: shorthand,
				endpoint: "milestones",
				model: [Milestone].self,
				queryItems: [URLQueryItem(name: "state", value: "all")]
			)
		}
	}
}
