import Foundation

struct PullRequestAnalyticsData: Codable {
	var isDependent: Bool
	var labelCount: Int
	var hasMilestone: Bool
}

final class PullRequestAnalyticsReporter {

	enum Error: Swift.Error {
		case urlFormattingError
		case firebaseConnection
		case noDataReceived
	}

	private let firebaseProjectId: String
	private let firebaseSecretToken: String

	init(firebaseProjectId: String, firebaseSecretToken: String) {
		self.firebaseProjectId = firebaseProjectId
		self.firebaseSecretToken = firebaseSecretToken
	}

	func report(_ pullRequestData: PullRequestAnalyticsData) throws {
		let reportUrl = URL(
			scheme: "https",
			host: "\(firebaseProjectId).firebaseio.com",
			path: "/pull-requests.json",
			queryItems: [URLQueryItem(name: "auth", value: firebaseSecretToken)]
		)

		guard let url = reportUrl else {
			throw Error.urlFormattingError
		}

		let session = URLSession(configuration: .default)
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.httpBody = try JSONEncoder().encode(pullRequestData)

		let response = session.synchronousDataTask(with: request)

		guard response.error == nil else {
			throw Error.firebaseConnection
		}
	}
}