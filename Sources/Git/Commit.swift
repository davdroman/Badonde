import Foundation

protocol CommitInteractor {
	func count(baseBranches: [String], targetBranch: String, after date: Date?) throws -> String
	func latestHashes(branches: [String], after date: Date?) throws -> String
}

public enum Commit { }

extension Commit {
	static var interactor: CommitInteractor = SwiftCLI()

	public static func count(baseBranch: Branch, targetBranch: Branch, after date: Date? = nil) throws -> Int {
		let commitCountRaw = try interactor.count(baseBranches: [baseBranch.fullName], targetBranch: targetBranch.name, after: date)
		guard let commitCount = Int(commitCountRaw) else {
			throw Error.numberNotFound
		}
		return commitCount
	}

	public static func count(baseBranches: [Branch], targetBranch: Branch, after date: Date? = nil) throws -> [(Branch, Int)] {
		let commitCountRaw = try interactor.count(baseBranches: baseBranches.map { $0.fullName }, targetBranch: targetBranch.name, after: date)
		return try commitCountRaw
			.components(separatedBy: "\n")
			.enumerated()
			.map {
				guard let count = Int($0.element) else {
					throw Error.numberNotFound
				}
				return (baseBranches[$0.offset], count)
			}
	}

	public static func latestHashes(branches: [Branch], after date: Date?) throws -> [String] {
		return try interactor.latestHashes(branches: branches.map { $0.fullName }, after: date)
			.components(separatedBy: "\n")
	}
}

extension Commit {
	public enum Error {
		case missingProperty
		case numberNotFound
	}
}

extension Commit.Error: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .missingProperty:
			return "Could not find required properties for commit in initialization"
		case .numberNotFound:
			return "Could not parse number for commit count"
		}
	}
}
