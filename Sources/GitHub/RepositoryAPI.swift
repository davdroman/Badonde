import Foundation

extension Repository {
	public final class API: GitHub.API {
		public func fetchRepository(for shorthand: Repository.Shorthand) throws -> Repository {
			return try fetchRepositoryInfo(
				for: shorthand,
				endpoint: nil,
				model: Repository.self
			)
		}
	}
}
