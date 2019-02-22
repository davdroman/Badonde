import SwiftCLI

final class Git {
	class func numberOfCommits(fromBranch: String, toBranch: String) -> Int {
		guard let commitCount = try? capture(bash: "git log origin/\(toBranch)..origin/\(fromBranch) --oneline | wc -l").stdout else {
			return 0
		}
		return Int(commitCount) ?? 0
	}

	class func baseBranch(forBranch branch: String) -> String {
		let developBranch = "develop"

		guard let localReleaseBranchesRaw = try? capture(bash: "git branch | grep \"release\"").stdout else {
			return developBranch
		}

		let releaseBranch = localReleaseBranchesRaw
			.replacingOccurrences(of: "\n  ", with: "\n")
			.split(separator: "\n")
			.filter { $0.hasPrefix("release/") }
			.compactMap { releaseBranch -> (version: Int, branch: String)? in
				let releaseBranch = String(releaseBranch)
				let versionNumberString = releaseBranch
					.replacingOccurrences(of: "release/", with: "")
					.replacingOccurrences(of: ".", with: "")
				guard let versionNumber = Int(versionNumberString) else {
					return nil
				}
				return (version: versionNumber, branch: releaseBranch)
			}
			.sorted { $0.version > $1.version }
			.first?
			.branch

		if let releaseBranch = releaseBranch {
			let numberOfCommitsToRelease = self.numberOfCommits(fromBranch: branch, toBranch: releaseBranch)
			let numberOfCommitsToDevelop = self.numberOfCommits(fromBranch: branch, toBranch: developBranch)

			if numberOfCommitsToRelease <= numberOfCommitsToDevelop {
				return releaseBranch
			}
		}

		return developBranch
	}

	class func remoteBranch(withTicketId ticketId: String) -> String? {
		guard let remoteBranchesRaw = try? capture(bash: "git branch -r | grep \"\(ticketId)\"").stdout else {
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
		guard let diff = try? capture(bash: "git diff \(baseBranch)..\(targetBranch)").stdout else {
			return false
		}
		return diff
			.split(separator: "\n")
			.filter { $0.hasPrefix("diff --git") }
			.contains(where: { $0.contains("\(word)") })
	}

	class func diffIncludesFile(baseBranch: String, targetBranch: String, withContent content: String) -> Bool {
		guard let diff = try? capture(bash: "git diff \(baseBranch)..\(targetBranch)").stdout else {
			return false
		}

		return !diff
			.split(separator: "\n")
			.filter { $0.hasPrefix("+++ b/") }
			.map { $0.dropFirst("+++ b/".count) }
			.compactMap { try? capture(bash: "cat \($0) | grep \(content)").stdout }
			.filter { !$0.isEmpty }
			.isEmpty
	}
}
