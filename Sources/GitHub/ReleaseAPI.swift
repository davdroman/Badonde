import Foundation
import Git

extension Release {
	public final class API: GitHub.API {
		public init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func getReleases(for shorthand: Repository.Shorthand) throws -> [Release] {
			return try get(
				endpoint: "/repos/\(shorthand.rawValue)/releases",
				responseType: [Release].self
			)
		}
	}
}
