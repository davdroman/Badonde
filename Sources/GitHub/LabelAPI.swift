import Foundation
import Git

extension Label {
	public final class API: GitHub.API {
		public init(accessToken: String) {
			super.init(authorization: .token(accessToken))
		}

		public func getLabels(for shorthand: Repository.Shorthand) throws -> [Label] {
			var labels: [Label] = []
			var currentPage = 1
			while true {
				let newLabels = try get(
					endpoint: "/repos/\(shorthand.rawValue)/labels",
					queryItems: [URLQueryItem(name: "page", value: "\(currentPage)")],
					responseType: [Label].self
				)
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
