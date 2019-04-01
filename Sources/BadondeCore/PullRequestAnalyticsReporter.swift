import Foundation
import Sugar

struct PullRequestAnalyticsData: Codable {
	var isDependent: Bool
	var labelCount: Int
	var hasMilestone: Bool
}

final class PullRequestAnalyticsReporter {

	private let firebaseProjectId: String
	private let firebaseSecretToken: String

	init(firebaseProjectId: String, firebaseSecretToken: String) {
		self.firebaseProjectId = firebaseProjectId
		self.firebaseSecretToken = firebaseSecretToken
	}

	func report(_ pullRequestData: PullRequestAnalyticsData) throws {
		let url = try URL(
			scheme: "https",
			host: "\(firebaseProjectId).firebaseio.com",
			path: "/pull-requests.json",
			queryItems: [URLQueryItem(name: "auth", value: firebaseSecretToken)]
		)

		let session = URLSession(configuration: .default)
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.httpBody = try JSONEncoder().encode(pullRequestData)

		let response = session.synchronousDataTask(with: request)

		if let error = response.error {
			throw error
		}

		guard let httpResponse = response.response as? HTTPURLResponse else {
			fatalError("Impossible!") // TODO: fix through use of Result in Swift 5 🤩 https://github.com/apple/swift-evolution/blob/master/proposals/0235-add-result.md
		}

		if 400...599 ~= httpResponse.statusCode {
			throw Error.http(httpResponse.statusCode)
		}
	}
}
