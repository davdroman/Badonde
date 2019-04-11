import Foundation

extension Release {
	public final class API: GitHub.API {
		public func getReleases(for shorthand: Repository.Shorthand) throws -> [Release] {
			return try get(
				[Release].self,
				for: shorthand,
				endpoint: "releases"
			)
		}
	}
}
