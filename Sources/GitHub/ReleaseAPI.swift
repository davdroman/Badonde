import Foundation

extension Release {
	public final class API: GitHub.API {
		public func fetchAllReleases(for shorthand: String) throws -> [Release] {
			return try fetchRepositoryInfo(
				for: shorthand,
				endpoint: "releases",
				model: [Release].self
			)
		}
	}
}
