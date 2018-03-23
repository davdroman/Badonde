import Foundation
import FileKit
import ShellOut
import Moya

public final class Badonde {
	private let arguments: [String]

	public init(arguments: [String] = CommandLine.arguments) {
		self.arguments = arguments
	}

	public func run() throws {
		guard Path.current.isGitRepository else {
			throw Error.directoryIsNotGitRepository
		}

		let branchName = try shellOut(to: "git rev-parse --symbolic-full-name --abbrev-ref HEAD")
//		let prCreationURL = "https://github.com/asosteam/asos-native-ios/compare/develop...\(branchName)?expand=1"
//		try shellOut(to: "open \(prCreationURL)")

		let diffs = try Git.diffFilesWithStatus(originBranch: branchName, targetBranch: "develop")

		let provider = MoyaProvider<GitHub>()
		provider.request(.userProfile("ashfurrow")) { result in
			print(result)
		}
	}
}

extension Path {
	var isGitRepository: Bool {
		return contains(".git")
	}
}

public final class Git {
	enum Status: String {
		case added = "A"
		case deleted = "D"
		case modified = "M"
	}

	struct DiffFile {
		let name: String
		let status: Status
	}

	static func diffFilesWithStatus(originBranch: String, targetBranch: String) throws -> [DiffFile] {
		return try shellOut(to: "git diff --name-status \(targetBranch)..\(originBranch)")
			.components(separatedBy: "\n")
			.flatMap { line in
				let filepath = String(line.dropFirst(2)) // Drops status char and \t, leaves path
				let filename = Path(filepath).fileName

				guard
					let rawStatus = line.first.map(String.init),
					let status = Status(rawValue: rawStatus)
				else {
					return nil
				}

				return DiffFile(name: filename, status: status)
			}
	}
}

extension Badonde {
	enum Error: Swift.Error {
		case directoryIsNotGitRepository
	}
}
