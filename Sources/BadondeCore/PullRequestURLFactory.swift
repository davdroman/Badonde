import Foundation

class PullRequestURLFactory: Codable {

	var repositoryShorthand: String
	var baseBranch: String?
	var targetBranch: String?
	var title: String?
	var labels: [String]?
	var milestone: String?

	init(repositoryShorthand: String) {
		self.repositoryShorthand = repositoryShorthand
	}

	var url: URL? {
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = "github.com"
		urlComponents.path = urlPath

		urlComponents.queryItems = [
			URLQueryItem(name: CodingKeys.title.stringValue, mandatoryValue: title),
			URLQueryItem(name: CodingKeys.labels.stringValue, mandatoryValue: labels?.joined(separator: ",")),
			URLQueryItem(name: CodingKeys.milestone.stringValue, mandatoryValue: milestone)
		].compactMap({ $0 }).nilIfEmpty

		return urlComponents.url
	}

	private var urlPath: String {
		var path = "/\(repositoryShorthand)/compare"

		switch (baseBranch, targetBranch) {
		case let (base?, target?):
			path.append(contentsOf: "/\(base)...\(target)")
		case let (nil, target?):
			path.append(contentsOf: "/\(target)")
		case let (base?, nil):
			path.append(contentsOf: "/\(base)...")
		case (nil, nil):
			path.append(contentsOf: "/")
		}

		return path
	}
}
