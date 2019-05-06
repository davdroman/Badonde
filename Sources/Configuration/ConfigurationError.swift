import Foundation

extension Configuration {
	public enum Error {
		case typeBridgingFailed(String, Any.Type)
		case invalidBridgingType(Any.Type)
	}
}

extension Configuration.Error: Swift.Error {
	public var localizedDescription: String {
		switch self {
		case let .typeBridgingFailed(value, type):
			return "Value '\(value)' could not be bridged to type '\(type)'"
		case let .invalidBridgingType(type):
			return "'\(type)' could not be used as bridging type"
		}
	}
}
