import Foundation

extension User {
	public final class API: GitHub.API {
		public init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func authenticatedUser() throws -> User {
			return try get(
				endpoint: "/user",
				responseType: User.self
			)
		}
	}
}
