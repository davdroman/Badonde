import Foundation
import Git

extension Label {
	public final class API: GitHub.API {
		public init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func labels(for shorthand: Repository.Shorthand, page: Int?, perPage: Int? = nil) throws -> [Label] {
			return try get(
				endpoint: "/repos/\(shorthand.rawValue)/labels",
				queryItems: [
					URLQueryItem(name: "page", mandatoryValue: page.map(String.init)),
					URLQueryItem(name: "per_page", mandatoryValue: perPage.map(String.init)),
				].compacted(),
				responseType: [Label].self
			)
		}

		public func allLabels(for shorthand: Repository.Shorthand) throws -> [Label] {
			var labels: [Label] = []
			var currentPage = 1
			let resultsPerPage = 100
			while true {
				let newLabels = try self.labels(for: shorthand, page: currentPage, perPage: resultsPerPage)
				labels += newLabels
				guard newLabels.count == resultsPerPage else {
					break
				}
				currentPage += 1
			}
			return labels
		}
	}
}
