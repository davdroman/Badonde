import Foundation
import SwiftCLI

final class SwiftCLI { }

extension SwiftCLI: RemoteInteractor {
	func getAllRemotes(atPath path: String) throws -> String {
		return try Task.capture(bash: "git -C '\(path)' remote").stdout
	}

	func getURL(forRemote remote: String, atPath path: String) throws -> String {
		return try Task.capture(bash: "git -C '\(path)' remote get-url \(remote)").stdout
	}

	func defaultBranch(forRemote remote: String, atPath path: String) throws -> String {
		return try Task.capture(bash: "git -C '\(path)' symbolic-ref refs/remotes/\(remote)/HEAD | sed 's@^refs/remotes/\(remote)/@@'").stdout
	}
}

extension SwiftCLI: BranchInteractor {
	func getCurrentBranch(atPath path: String) throws -> String {
		return try Task.capture(bash: "git -C '\(path)' rev-parse --abbrev-ref HEAD").stdout
	}

	func getAllBranches(from source: Branch.Source, atPath path: String) throws -> String {
		switch source {
		case .local:
			return try Task.capture(bash: "git -C '\(path)' branch | cut -c 3-").stdout
		case .remote(let remote):
			return try Task.capture(bash: "git -C '\(path)' branch -r | grep '\(remote.name)/' | cut -c 3-").stdout
		}
	}
}

extension SwiftCLI: CommitInteractor {
	func count(baseBranches: [String], targetBranch: String, after date: Date?, atPath path: String) throws -> String {
		let afterParameter = (date?.timeIntervalSince1970).map { " --after=\"\(Int($0))\"" } ?? ""
		let command = baseBranches.map { "git -C '\(path)' rev-list --count\(afterParameter) \($0)..\(targetBranch)" }.joined(separator: ";")
		return try Task.capture(bash: command).stdout
	}

	func latestHashes(branches: [String], after date: Date?, atPath path: String) throws -> String {
		let afterParameter = date.map { " --after=\"\(ISO8601DateFormatter().string(from: $0))\"" } ?? ""
		let command = branches
			.map { "git -C '\(path)' log -1 --pretty=format:'%h'\(afterParameter) -s \($0) | grep . || echo 'no_commit'" }
			.joined(separator: ";")
		return try Task.capture(bash: command).stdout.replacingOccurrences(of: "no_commit", with: "")
	}
}

extension SwiftCLI: DiffInteractor {
	func diff(baseBranch: String, targetBranch: String, atPath path: String) throws -> String {
		return try Task.capture(bash: "git -C '\(path)' diff --no-prefix \(baseBranch)...\(targetBranch)").stdout
	}
}

extension SwiftCLI: PushInteractor {
	func perform(remote: String, branch: String, atPath path: String) throws {
		_ = try Task.capture(bash: "git -C '\(path)' push \(remote) \(branch)")
	}
}

extension SwiftCLI: RepositoryInteractor {
	func getTopLevelPath(forPath path: String) throws -> String {
		return try Task.capture(bash: "git -C \(path) rev-parse --show-toplevel").stdout
	}
}

extension SwiftCLI: TagInteractor {
	func getAllTags(atPath path: String) throws -> String {
		return try Task.capture(bash: "git -C \(path) tag --sort=-creatordate").stdout
	}
}
