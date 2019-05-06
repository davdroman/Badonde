import Foundation

extension Configuration {
	public enum Error {
		case typeBridgingFailed(String, Any.Type)
		case invalidBridgingType(Any.Type)
		case invalidValueType(Any.Type)
		case incompatibleKeyPath(KeyPath)
	}
}

extension Configuration.Error: Swift.Error {
	public var localizedDescription: String {
		switch self {
		case let .typeBridgingFailed(value, type):
			return "Value '\(value)' could not be bridged to type '\(type)'"
		case let .invalidBridgingType(type):
			return "'\(type)' cannot be used as bridging type"
		case let .invalidValueType(type):
			return "'\(type)' cannot be used as value type"
		case let .incompatibleKeyPath(keyPath):
			return "'\(keyPath.rawValue)' could not be used as a key"
		}
	}
}
