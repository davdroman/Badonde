import SwiftCLI

extension BurghCommand {
	enum Error {
		case noGitRepositoryFound
		case invalidBaseBranch(String)
		case invalidBranchFormat(String)
		case missingGitRemote
		case invalidPullRequestURL
	}
}

extension BurghCommand.Error: ProcessError {
	var message: String? {
		switch self {
		case .noGitRepositoryFound:
			return "☛ No Git repository found in current directory"
		case .invalidBaseBranch(let branch):
			return "☛ No remote branch found matching specified term '\(branch)'"
		case .invalidBranchFormat(let branch):
			return "☛ Invalid ticket format for current branch '\(branch)'"
		case .missingGitRemote:
			return "☛ Git remote named 'origin' is missing, please add it with `git remote add origin {git_url}`"
		case .invalidPullRequestURL:
			return "☛ Could not form a valid pull request URL"
		}
	}
}
