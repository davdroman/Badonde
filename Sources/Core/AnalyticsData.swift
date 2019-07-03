import Foundation
import struct BadondeKit.Output
import Sugar

public struct PullRequestAnalyticsData: Encodable {
	public var info: [String: AnyCodable]
	public var elapsedTime: TimeInterval
	public var timestamp: Date
	public var version: String
}

extension PullRequestAnalyticsData {
	public init(outputAnalyticsData: Output.AnalyticsData, startDate: Date, version: String) {
		self.init(
			info: outputAnalyticsData.info,
			elapsedTime: Date().timeIntervalSince(startDate),
			timestamp: startDate,
			version: version
		)
	}
}

public struct ErrorAnalyticsData: Encodable {
	public var description: String
	public var elapsedTime: TimeInterval
	public var timestamp: Date
	public var version: String
}

extension Error {
	public func analyticsData(startDate: Date, version: String) -> ErrorAnalyticsData {
		return ErrorAnalyticsData(
			description: localizedDescription,
			elapsedTime: Date().timeIntervalSince(startDate),
			timestamp: startDate,
			version: version
		)
	}
}
