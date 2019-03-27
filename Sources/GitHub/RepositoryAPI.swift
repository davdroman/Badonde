import Foundation

extension Repository {
	public final class API: GitHub.API {
		public func getRepository(with shorthand: Repository.Shorthand) throws -> Repository {
			return try get(
				Repository.self,
				for: shorthand,
				endpoint: nil
			)
		}
	}
}
