import Foundation

extension Repository {
	public final class API: GitHub.API {
		public init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func get(for shorthand: Repository.Shorthand) throws -> Repository {
			return try get(
				endpoint: "/repos/\(shorthand.rawValue)",
				responseType: Repository.self
			)
		}
	}
}
