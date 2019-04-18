import Foundation

public struct Branch: Equatable {
	public enum Source: Equatable {
		case local
		case remote(String)

		public var remoteName: String? {
			switch self {
			case .local:
				return nil
			case .remote(let remoteName):
				return remoteName
			}
		}
	}

	public let name: String
	public var source: Source

	public var fullName: String {
		let prefix = source.remoteName.map { $0 + "/" } ?? ""
		return prefix + name
	}

	public init(name: String, source: Source) {
		switch source {
		case .local:
			self.name = name
		case .remote(let remote):
			if let prefixRange = name.range(of: remote + "/") {
				self.name = name.replacingCharacters(in: ..<prefixRange.upperBound, with: "")
			} else {
				self.name = name
			}
		}

		self.source = source
	}
}
