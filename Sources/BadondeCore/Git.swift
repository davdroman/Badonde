import Foundation
import SwiftCLI

final class Git {
	typealias BranchAndCommits = (branch: String, commits: Int)

	class func numberOfCommits(fromBranch: String, toBranches: [String], after date: Date = .init(timeIntervalSince1970: 0)) -> [BranchAndCommits] {
		let unixDate = Int(date.timeIntervalSince1970)
		let commands = toBranches.map { "git rev-list --count --after=\"\(unixDate)\" \($0)..\(fromBranch)" }.joined(separator: ";")

		guard let commitCount = try? capture(bash: commands).stdout else {
			return []
		}

		return commitCount
			.split(separator: "\n")
			.enumerated()
			.compactMap {
				guard let element = Int($0.element) else {
					return nil
				}
				return (branch: toBranches[$0.offset], commits: element)
			}
	}

	class func latestCommitDate(for branch: String) -> Date? {
		guard
			let rawLatestCommitDateUnix = try? capture(bash: "git log -1 --pretty=format:%ct \(branch)").stdout,
			let latestCommitDateUnix = TimeInterval(rawLatestCommitDateUnix)
		else {
			return nil
		}
		return Date(timeIntervalSince1970: latestCommitDateUnix)
	}

	class func closestBranch(to targetBranch: String, priorityBranch: String? = nil) -> String? {
		guard let rawBranches = try? capture(bash: "git branch | cut -c 3-").stdout else {
			return nil
		}

		let branches = rawBranches.split(separator: "\n").map({ String($0) })

		let commitsAndBranches = numberOfCommits(
			fromBranch: targetBranch,
			toBranches: branches,
			after: Date(timeIntervalSinceNow: -2592000) // 1 month ago
		)

		let sortedBranchesWithSameCommits = commitsAndBranches
			.filter { $0.commits > 0 }
			.sorted { $0.commits < $1.commits }
			.reduce([BranchAndCommits]()) { (result, branchAndCommits) -> [BranchAndCommits] in
				guard let lastBranchAndCommits = result.last, lastBranchAndCommits.commits != branchAndCommits.commits else {
					return result + [branchAndCommits]
				}
				return result
			}
			.map { $0.branch }

		if let priorityBranch = priorityBranch, sortedBranchesWithSameCommits.contains(priorityBranch) {
			return priorityBranch
		} else {
			return sortedBranchesWithSameCommits.first
		}
	}

	class func remoteBranch(containing term: String) -> String? {
		guard let remoteBranchesRaw = try? capture(bash: "git branch -r | grep \"\(term)\"").stdout else {
			return nil
		}

		return remoteBranchesRaw
			.replacingOccurrences(of: "  ", with: "")
			.split(separator: "\n")
			.map { $0.replacingOccurrences(of: "origin/", with: "") }
			.first
	}

	class func getRepositoryShorthand() -> String? {
		guard let repositoryURL = try? capture(bash: "git ls-remote --get-url origin").stdout else {
			return nil
		}
		return repositoryURL
			.drop(while: { $0 != ":" })
			.prefix(while: { $0 != "." })
			.replacingOccurrences(of: ":", with: "")
			.replacingOccurrences(of: ".", with: "")
	}

	class func diffIncludesFilename(baseBranch: String, targetBranch: String, containing word: String) -> Bool {
		guard let diff = try? capture(bash: "git diff \(baseBranch)...\(targetBranch)").stdout else {
			return false
		}
		return diff
			.split(separator: "\n")
			.filter { $0.hasPrefix("diff --git") }
			.contains(where: { $0.contains("\(word)") })
	}

	class func diffIncludesFile(baseBranch: String, targetBranch: String, withContent content: String) -> Bool {
		guard let diff = try? capture(bash: "git diff \(baseBranch)...\(targetBranch)").stdout else {
			return false
		}

		return !diff
			.split(separator: "\n")
			.filter { $0.hasPrefix("+++ b/") }
			.map { $0.dropFirst("+++ b/".count) }
			.compactMap { try? capture(bash: "cat \($0) | grep \"\(content)\"").stdout }
			.filter { !$0.isEmpty }
			.isEmpty
	}
}
