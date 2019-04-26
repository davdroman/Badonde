import Foundation
import GitHub
import Sugar

extension PullRequest {
	func analyticsData(startDate: Date) -> AnalyticsReporter.Data {
		return AnalyticsReporter.Data(
			isDependent: baseBranch.isTicketBranch,
			labelCount: labels.count,
			hasMilestone: milestone != nil,
			elapsedTime: Date().timeIntervalSince(startDate),
			timestamp: startDate,
			version: CommandLineTool.Constant.version
		)
	}
}

extension PullRequest {
	final class AnalyticsReporter {
		struct Data: Codable {
			var isDependent: Bool
			var labelCount: Int
			var hasMilestone: Bool
			var elapsedTime: TimeInterval
			var timestamp: Date
			var version: String
		}

		private let firebaseProjectId: String
		private let firebaseSecretToken: String

		init(firebaseProjectId: String, firebaseSecretToken: String) {
			self.firebaseProjectId = firebaseProjectId
			self.firebaseSecretToken = firebaseSecretToken
		}

		func report(_ analyticsData: Data) throws {
			let url = try URL(
				scheme: "https",
				host: "\(firebaseProjectId).firebaseio.com",
				path: "/pull-requests.json",
				queryItems: [URLQueryItem(name: "auth", value: firebaseSecretToken)]
			)

			let session = URLSession(configuration: .default)
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			let encoder = JSONEncoder()
			encoder.dateEncodingStrategy = .secondsSince1970
			request.httpBody = try encoder.encode(analyticsData)

			let resultValue = try session.synchronousDataTask(with: request).get()
			let statusCode = (resultValue.response as? HTTPURLResponse)?.statusCode ?? 200

			if 400...599 ~= statusCode {
				throw Error.http(statusCode)
			}
		}
	}
}
