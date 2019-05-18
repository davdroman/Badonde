import Foundation

extension Branch {
	public enum Error {
		case nameContainsInvalidCharacters
	}
}

extension Branch.Error: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .nameContainsInvalidCharacters:
			return "Name contains invalid characters"
		}
	}
}
