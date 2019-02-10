import Foundation
import SwiftCLI

extension TicketId {
	init?(branchName: String) {
		guard let ticketId = branchName.split(separator: "_").first else {
			return nil
		}
		self.init(rawValue: String(ticketId))
	}
}

extension IssueType {
	var isBug: Bool {
		return ["Bug", "Story Defect"].contains(name)
	}
}

class BurghCommand: Command {
	enum Error: Swift.Error {
		case invalidBaseTicketId
		case invalidBranchFormat
		case invalidPullRequestURL
		case missingGitRemote
	}

	let name = "burgh"
	let shortDescription = "Generates and opens PR page"
	let baseTicket = Key<String>("-t", "--base-ticket", description: "Ticket ID of the base branch")

	func numberOfCommits(fromBranch: String, toBranch: String) -> Int {
		guard let commitCount = try? capture(bash: "git log origin/\(toBranch)..origin/\(fromBranch) --oneline | wc -l").stdout else {
			return 0
		}
		return Int(commitCount) ?? 0
	}

	func baseBranch(forBranch branch: String) -> String {
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

	func branch(withTicketId ticketId: String) -> String? {
		guard let localBranchesRaw = try? capture(bash: "git branch -a | grep \"\(ticketId)\"").stdout else {
			return nil
		}

		return localBranchesRaw
			.replacingOccurrences(of: "  ", with: "")
			.split(separator: "\n")
			.map { $0.replacingOccurrences(of: "remotes/origin/", with: "") }
			.first
	}

	func getRepositoryShorthand() -> String? {
		guard let repositoryURL = try? capture(bash: "git ls-remote --get-url origin").stdout else {
			return nil
		}
		return repositoryURL
			.drop(while: { $0 != ":" })
			.prefix(while: { $0 != "." })
			.replacingOccurrences(of: ":", with: "")
			.replacingOccurrences(of: ".", with: "")
	}

	func execute() throws {
		guard
			let currentBranchName = try? capture(bash: "git rev-parse --abbrev-ref HEAD").stdout,
			let ticketId = TicketId(branchName: currentBranchName)
		else {
			throw Error.invalidBranchFormat
		}

		guard let repoShorthand = getRepositoryShorthand() else {
			throw Error.missingGitRemote
		}

		// Set PR base and target branches
		let pullRequestURLFactory = PullRequestURLFactory(repositoryShorthand: repoShorthand)
		// TODO: fetch possible dependency branch from related tickets?
		if let baseTicket = baseTicket.value {
			guard let ticketBranch = branch(withTicketId: baseTicket) else {
				throw Error.invalidBranchFormat
			}
			pullRequestURLFactory.baseBranch = ticketBranch
		} else {
			pullRequestURLFactory.baseBranch = baseBranch(forBranch: currentBranchName)
		}
		pullRequestURLFactory.targetBranch = currentBranchName

		// Fetch or prompt for JIRA and GitHub credentials
		let accessTokenStore = AccessTokenStore()
		let accessTokenConfig = getOrPromptAccessTokenConfig(for: accessTokenStore)

		let repoInfoFetcher = GitHubRepositoryInfoFetcher(accessToken: accessTokenConfig.githubAccessToken)
		let ticketFetcher = TicketFetcher(email: accessTokenConfig.jiraEmail, apiToken: accessTokenConfig.jiraApiToken)

		// Fetch repo and ticket info
		let repoInfo = try repoInfoFetcher.fetchRepositoryInfo(withRepositoryShorthand: repoShorthand)
		let ticket = try ticketFetcher.fetchTicket(with: ticketId)

		// Set PR title
		pullRequestURLFactory.title = "[\(ticket.key)] \(ticket.fields.summary)"

		// Set PR labels
		let repoLabels = repoInfo.labels.map { $0.name }
		var pullRequestLabels: [String] = []

		// Append Bug label if ticket is a bug
		if ticket.fields.issueType.isBug {
			if let bugLabel = repoLabels.fuzzyMatch(word: "bug") {
				pullRequestLabels.append(bugLabel)
			}
		}

		// Append ticket's epic label if similar name is found in repo labels
		if let epic = ticket.fields.epicSummary {
			if let epicLabel = repoLabels.fuzzyMatch(word: epic) {
				pullRequestLabels.append(epicLabel)
			}
		}

		pullRequestURLFactory.labels = pullRequestLabels.nilIfEmpty

		// Set PR milestone from ticket fix version
		if
			let rawMilestone = ticket.fields.fixVersions.first?.name,
			!rawMilestone.isEmpty
		{
			let repoMilestones = repoInfo.milestones.map({ $0.title })
			if let milestone = repoMilestones.fuzzyMatch(word: rawMilestone) {
				pullRequestURLFactory.milestone = milestone
			}
		}

		guard let pullRequestURL = pullRequestURLFactory.url else {
			throw Error.invalidPullRequestURL
		}

		try run(bash: "open \"\(pullRequestURL)\"")
	}

	func getOrPromptAccessTokenConfig(for store: AccessTokenStore) -> AccessTokenConfig {
		let accessTokenConfig: AccessTokenConfig

		if let config = store.config {
			accessTokenConfig = config
		} else {
			let jiraEmailInput = Input.readLine(
				prompt: "Enter JIRA email address:",
				secure: false,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "'\(input)' is invalid; \(invalidInputReason)"
				}
			)
			let jiraApiTokenInput = Input.readLine(
				prompt: "Enter JIRA API token (generated at https://id.atlassian.com/manage/api-tokens):",
				secure: true,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "Invalid token; \(invalidInputReason)"
				}
			)
			let githubAccessTokenInput = Input.readLine(
				prompt: "Enter GitHub API token (generated at https://github.com/settings/tokens):",
				secure: true,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "Invalid token; \(invalidInputReason)"
				}
			)
			accessTokenConfig = AccessTokenConfig(
				jiraEmail: jiraEmailInput,
				jiraApiToken: jiraApiTokenInput,
				githubAccessToken: githubAccessTokenInput
			)
			store.config = accessTokenConfig
		}

		return accessTokenConfig
	}
}
