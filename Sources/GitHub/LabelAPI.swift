import Foundation

extension Label {
	public final class API: GitHub.API {
		public func fetchAllRepositoryLabels(for shorthand: Repository.Shorthand) throws -> [Label] {
			var labels: [Label] = []
			var currentPage = 1
			while true {
				let newLabels = try fetchRepositoryInfo(
					for: shorthand,
					endpoint: "labels",
					model: [Label].self,
					queryItems: [URLQueryItem(name: "page", value: "\(currentPage)")]
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
