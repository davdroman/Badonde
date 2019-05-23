import Foundation
import SwiftCLI

final class SwiftCLI { }

extension SwiftCLI: RemoteInteractor {
	func getAllRemotes() throws -> String {
		return try capture(bash: "git remote").stdout
	}

	func getURL(forRemote remote: String) throws -> String {
		return try capture(bash: "git remote get-url \(remote)").stdout
	}

	func defaultBranch(forRemote remote: String) throws -> String {
		return try capture(bash: "git symbolic-ref refs/remotes/\(remote)/HEAD | sed 's@^refs/remotes/\(remote)/@@'").stdout
	}
}

extension SwiftCLI: BranchInteractor {
	func getCurrentBranch() throws -> String {
		return try capture(bash: "git rev-parse --abbrev-ref HEAD").stdout
	}

	func getAllBranches(from source: Branch.Source) throws -> String {
		switch source {
		case .local:
			return try capture(bash: "git branch | cut -c 3-").stdout
		case .remote(let remote):
			return try capture(bash: "git branch -r | grep '\(remote.name)/' | cut -c 3-").stdout
		}
	}
}

extension SwiftCLI: CommitInteractor {
	func count(baseBranches: [String], targetBranch: String, after date: Date?) throws -> String {
		let afterParameter = (date?.timeIntervalSince1970).map { " --after=\"\(Int($0))\"" } ?? ""
		let command = baseBranches.map { "git rev-list --count\(afterParameter) \($0)..\(targetBranch)" }.joined(separator: ";")
		return try capture(bash: command).stdout
	}

	func latestHashes(branches: [String], after date: Date?) throws -> String {
		let afterParameter = date.map { " --after=\"\(ISO8601DateFormatter().string(from: $0))\"" } ?? ""
		let command = branches
			.map { "git log -1 --pretty=format:'%h'\(afterParameter) -s \($0) | grep . || echo 'no_commit'" }
			.joined(separator: ";")
		return try capture(bash: command).stdout.replacingOccurrences(of: "no_commit", with: "")
	}
}

extension SwiftCLI: DiffInteractor {
	func diff(baseBranch: String, targetBranch: String) throws -> String {
		return try capture(bash: "git diff --no-prefix \(baseBranch)...\(targetBranch)").stdout
	}
}

extension SwiftCLI: PushInteractor {
	func perform(remote: String, branch: String) throws {
		_ = try capture(bash: "git push \(remote) \(branch)")
	}
}

extension SwiftCLI: RepositoryInteractor {
	func getTopLevelPath(from path: String) throws -> String {
		return try capture(bash: "git -C \(path) rev-parse --show-toplevel").stdout
	}
}
