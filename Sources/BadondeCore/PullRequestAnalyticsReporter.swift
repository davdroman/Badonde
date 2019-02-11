import Foundation

final class PullRequestAnalyticsReporter {

	private let firebaseApiToken: String

	var isDependent: Bool = false
	var labelCount: Int = 0
	var hasMilestone: Bool = false

	init(firebaseApiToken: String) {
		self.firebaseApiToken = firebaseApiToken
	}

	func report() {
		// TODO: implement
	}
}
