import Foundation
import struct BadondeKit.Output
import Sugar

struct PullRequestAnalyticsData: Encodable {
	var info: [String: AnyCodable]
	var elapsedTime: TimeInterval
	var timestamp: Date
	var version: String
}

extension PullRequestAnalyticsData {
	init(outputAnalyticsData: Output.AnalyticsData, startDate: Date) {
		self.init(
			info: outputAnalyticsData.info,
			elapsedTime: Date().timeIntervalSince(startDate),
			timestamp: startDate,
			version: CommandLineTool.Constant.version
		)
	}
}

struct ErrorAnalyticsData: Encodable {
	var description: String
	var elapsedTime: TimeInterval
	var timestamp: Date
	var version: String
}

extension Error {
	func analyticsData(startDate: Date) -> ErrorAnalyticsData {
		return ErrorAnalyticsData(
			description: localizedDescription,
			elapsedTime: Date().timeIntervalSince(startDate),
			timestamp: startDate,
			version: CommandLineTool.Constant.version
		)
	}
}
