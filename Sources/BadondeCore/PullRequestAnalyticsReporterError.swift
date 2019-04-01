import Foundation
import GitHub

extension PullRequest.AnalyticsReporter {
	enum Error {
		case http(Int)
	}
}

extension PullRequest.AnalyticsReporter.Error: Swift.Error {
	var localizedDescription: String {
		switch self {
		case .http(let statusCode):
			return "Firebase API call failed with HTTP status code \(statusCode)"
		}
	}
}
