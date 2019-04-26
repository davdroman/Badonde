import Foundation

public protocol BranchInteractor {
	func getAllBranches(from source: Branch.Source) throws -> String
	func latestCommit(for branch: Branch) throws -> String
}

public struct Branch: Equatable {
	public enum Source: Equatable {
		case local
		case remote(Remote)

		public var remote: Remote? {
			switch self {
			case .local:
				return nil
			case .remote(let remote):
				return remote
			}
		}
	}

	public let name: String
	public var source: Source

	public var fullName: String {
		let prefix = source.remote.map { $0.name + "/" } ?? ""
		return prefix + name
	}

	public init(name: String, source: Source) throws {
		guard name.rangeOfCharacter(from: .whitespaces) == nil else {
			throw Error.nameContainsInvalidCharacters
		}

		switch source {
		case .local:
			self.name = name
		case .remote(let remote):
			if let prefixRange = name.range(of: remote.name + "/") {
				self.name = name.replacingCharacters(in: ..<prefixRange.upperBound, with: "")
			} else {
				self.name = name
			}
		}

		self.source = source
	}
}

extension Branch {
	public static func getAll(from source: Branch.Source, interactor: BranchInteractor? = nil) throws -> [Branch] {
		let interactor = interactor ?? SwiftCLI()

		return try interactor.getAllBranches(from: source)
			.components(separatedBy: "\n")
			.compactMap { try? Branch(name: $0, source: source) }
	}

	public func latestCommit(interactor: BranchInteractor? = nil) throws -> Commit {
		let interactor = interactor ?? SwiftCLI()

		return try Commit(rawCommitContent: interactor.latestCommit(for: self))
	}

	public func isAhead(of remote: Remote, interactor: CommitInteractor? = nil) throws -> Bool {
		let interactor = interactor ?? SwiftCLI()

		var remoteBranch = self
		remoteBranch.source = .remote(remote)

		return try Commit.count(baseBranch: remoteBranch, targetBranch: self, interactor: interactor) > 0
	}

	public func parent(for remote: Remote, branchInteractor: BranchInteractor? = nil, commitInteractor: CommitInteractor? = nil, remoteInteractor: RemoteInteractor? = nil) throws -> Branch {
		let branchInteractor = branchInteractor ?? SwiftCLI()
		let commitInteractor = commitInteractor ?? SwiftCLI()
		let remoteInteractor = remoteInteractor ?? SwiftCLI()

		let defaultBranch = try remote.defaultBranch(interactor: remoteInteractor)

		let allRemoteBranches = try Branch.getAll(from: .remote(remote), interactor: branchInteractor)

		let commitsAndBranches = try Commit.count(
			baseBranches: allRemoteBranches,
			targetBranch: self,
			after: Date(timeIntervalSinceNow: -2592000), // 1 month ago
			interactor: commitInteractor
		)

		let branchesWithLowestEqualCommitCount = commitsAndBranches
			.filter { $0.1 > 0 }
			.sorted { $0.1 < $1.1 }
			.reduce([(Branch, Int)]()) { (result, branchAndCommits) -> [(Branch, Int)] in
				guard let lastBranchAndCommits = result.last, lastBranchAndCommits.1 != branchAndCommits.1 else {
					return result + [branchAndCommits]
				}
				return result
			}
			.map { $0.0 }

		guard
			!branchesWithLowestEqualCommitCount.contains(defaultBranch),
			let parentBranch = branchesWithLowestEqualCommitCount.first
		else {
			return defaultBranch
		}

		return parentBranch
	}
}
