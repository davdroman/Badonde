import Foundation

extension Branch {
	public enum Error {
		case nameContainsInvalidCharacters
	}
}

extension Branch.Error: Swift.Error {
	public var localizedDescription: String {
		switch self {
		case .nameContainsInvalidCharacters:
			return "Name contains invalid characters"
		}
	}
}
