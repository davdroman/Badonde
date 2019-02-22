import SwiftCLI

extension BurghCommand {
	enum Error {
		case noGitRepositoryFound
		case invalidBaseTicketId(String)
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
		case .invalidBaseTicketId(let ticketId):
			return "☛ No remote branch found matching specified base ticket id '\(ticketId)'"
		case .invalidBranchFormat(let branch):
			return "☛ Invalid ticket format for current branch '\(branch)'"
		case .missingGitRemote:
			return "☛ Git remote named 'origin' is missing, please add it with `git remote add origin {git_url}`"
		case .invalidPullRequestURL:
			return "☛ Could not form a valid pull request URL"
		}
	}
}
