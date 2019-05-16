import Foundation

extension Repository {
	public struct Shorthand {
		public let username: String
		public let repository: String
	}
}

extension Repository.Shorthand: Equatable, RawRepresentable {
	private enum Constant {
		static let componentRegex = #"^[a-zA-Z\d](?:[a-zA-Z\d]|-(?=[a-zA-Z\d])){0,38}$"#
	}

	public var rawValue: String {
		return username + "/" + repository
	}

	public init?(rawValue: String) {
		let components = rawValue.split(separator: "/").map(String.init)

		guard
			let username = components.first,
			let repository = components.dropFirst().first,
			username.matchesRegex(Constant.componentRegex),
			repository.matchesRegex(Constant.componentRegex)
		else {
			return nil
		}

		self.username = username
		self.repository = repository
	}
}

extension Repository.Shorthand: ExpressibleByStringLiteral {
	public init(stringLiteral value: StaticString) {
		guard let _self = type(of: self).init(rawValue: String(staticString: value)) else {
			fatalError("Failed to initialize repository shorthand with string literal '\(value)'")
		}
		self = _self
	}
}

extension Repository.Shorthand: CustomStringConvertible {
	public var description: String {
		return rawValue
	}
}

extension Repository.Shorthand: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawValue = try container.decode(String.self)
		guard let _self = type(of: self).init(rawValue: rawValue) else {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Failed to decode repository shorthand"
			)
		}
		self = _self
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}

extension Repository.Shorthand {
	public enum Error {
		case parsing
	}
}

extension Repository.Shorthand.Error: Swift.Error {
	public var localizedDescription: String {
		switch self {
		case .parsing:
			return "Shorthand does not match required pattern for parsing"
		}
	}
}
