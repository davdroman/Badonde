import Foundation

extension Diff {
	public enum Error {
		case hunkHeaderMissing
		case filePathsNotFound
	}
}

extension Diff.Error: Swift.Error {
	public var localizedDescription: String {
		switch self {
		case .filePathsNotFound:
			return "Could not find +++ &/or --- files"
		case .hunkHeaderMissing:
			return "Found a diff line without a hunk header"
		}
	}
}
