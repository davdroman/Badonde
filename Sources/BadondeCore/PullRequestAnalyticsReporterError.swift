import Foundation

extension PullRequestAnalyticsReporter {
	enum Error {
		case firebaseConnectionFailed(Swift.Error)
		case noDataReceived
	}
}

extension PullRequestAnalyticsReporter.Error: Swift.Error {
	var localizedDescription: String {
		switch self {
		case .firebaseConnectionFailed(let error):
			return "☛ Firebase API call failed with error: \(error)"
		case .noDataReceived:
			return "☛ No data received for Firebase API call"
		}
	}
}
