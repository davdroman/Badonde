import Foundation

extension PullRequestAnalyticsReporter {
	enum Error {
		case http(Int)
	}
}

extension PullRequestAnalyticsReporter.Error: Swift.Error {
	var localizedDescription: String {
		switch self {
		case .http(let statusCode):
			return "Firebase API call failed with HTTP status code \(statusCode)"
		}
	}
}
