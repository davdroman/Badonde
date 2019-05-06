import Foundation
import Sugar

extension Configuration {
	public struct KeyPath: RawRepresentable, ExpressibleByStringLiteral {
		public let rawValue: String
		public let description: String?

		public init?(rawValue: String, description: String?) {
			guard rawValue.matchesRegex(#"^(\s*[\d\w]+([.]?[\d\w]+)+\s*)+$"#) else {
				return nil
			}
			self.rawValue = rawValue
			self.description = description
		}

		public init?(rawValue: String) {
			self.init(rawValue: rawValue, description: nil)
		}

		public init(stringLiteral value: StaticString) {
			guard let _self = type(of: self).init(rawValue: String(staticString: value)) else {
				fatalError("Failed to initialize config keypath with string literal '\(value)'")
			}
			self = _self
		}
	}
}

extension Configuration.KeyPath: Hashable, Equatable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}

	public static func == (lhs: Configuration.KeyPath, rhs: Configuration.KeyPath) -> Bool {
		return lhs.rawValue == rhs.rawValue
	}
}

extension Configuration.KeyPath {
	private var keys: [String] {
		return rawValue.components(separatedBy: ".")
	}

	private func isPartial(of keyPath: Configuration.KeyPath) -> Bool {
		guard self != keyPath else {
			return false
		}
		return zip(keys, keyPath.keys).allSatisfy { $0 == $1 }
	}

	func isCompatible(in keyPaths: [Configuration.KeyPath]) -> Bool {
		return !keyPaths.contains(where: { self.isPartial(of: $0) })
	}
}
