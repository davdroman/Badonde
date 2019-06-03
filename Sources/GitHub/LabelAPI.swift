import Foundation
import Git

extension Label {
	public final class API: GitHub.API {
		public init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func labels(for shorthand: Repository.Shorthand, page: Int) throws -> [Label] {
			return try get(
				endpoint: "/repos/\(shorthand.rawValue)/labels",
				queryItems: [URLQueryItem(name: "page", value: String(page))],
				responseType: [Label].self
			)
		}

		public func allLabels(for shorthand: Repository.Shorthand) throws -> [Label] {
			var labels: [Label] = []
			var currentPage = 1
			while true {
				let newLabels = try self.labels(for: shorthand, page: currentPage)
				guard !newLabels.isEmpty else {
					break
				}
				labels += newLabels
				currentPage += 1
			}
			return labels
		}
	}
}
