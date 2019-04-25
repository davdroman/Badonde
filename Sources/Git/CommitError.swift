import Foundation

extension Commit {
	public enum Error {
		case missingProperty
	}
}

extension Commit.Error: Swift.Error {
	public var localizedDescription: String {
		switch self {
		case .missingProperty:
			return "Could not find required properties for commit in initialization"
		}
	}
}
