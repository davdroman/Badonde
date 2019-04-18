import Foundation

public struct Remote: Equatable {
	public var name: String
	public var url: URL

	public init(name: String, url: URL) {
		self.name = name
		self.url = url
	}
}
