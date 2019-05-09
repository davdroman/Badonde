import Foundation

extension ConfigCommand {
	enum Error {
		case incompatibleKey(String)
		case valueMissing(forKey: String)
	}
}

extension ConfigCommand.Error: Swift.Error {
	var localizedDescription: String {
		switch self {
		case let .incompatibleKey(key):
			return "'\(key)' cannot not be used as a key"
		case let .valueMissing(key):
			return "Missing value to set to '\(key)'"
		}
	}
}
