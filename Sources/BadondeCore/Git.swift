import SwiftCLI

extension TicketId {
	init?(branchName: String) {
		guard let ticketId = branchName.split(separator: "_").first else {
			return nil
		}
		self.init(rawValue: String(ticketId))
	}
}

extension String {
	var isTicketBranch: Bool {
		return split(separator: "_").first?.contains("-") == true
	}
}

final class Git {
	class func numberOfCommits(fromBranch: String, toBranch: String) -> Int {
		guard let commitCount = try? capture(bash: "git log origin/\(toBranch)..origin/\(fromBranch) --oneline | wc -l").stdout else {
			return 0
		}
		return Int(commitCount) ?? 0
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
