import Foundation

extension BurghCommand {
	enum Error {
		case gitRemoteMissing(String)
		case noGitRemotes
		case invalidBaseBranch(String)
		case invalidBranchFormat(String)
		case noTicketKey
		case invalidPullRequestURL
	}
}

extension BurghCommand.Error: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .gitRemoteMissing(let remoteName):
			return "Git remote '\(remoteName)' is missing, please add it with `git remote add \(remoteName) [GIT_URL]`"
		case .noGitRemotes:
			return "Git remote is missing, please add it with `git remote add [REMOTE_NAME] [GIT_URL]`"
		case .invalidBaseBranch(let branch):
			return "No remote branch found matching specified term '\(branch)'"
		case .invalidBranchFormat(let branch):
			return "Invalid ticket format for current branch '\(branch)'"
		case .noTicketKey:
			return "Current branch is a 'NO-TICKET', please use a ticket prefixed branch"
		case .invalidPullRequestURL:
			return "Could not form a valid pull request URL"
		}
	}
}
