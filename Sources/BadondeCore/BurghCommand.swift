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
		case invalidBranchFormat
		case invalidPullRequestURL
	}

	let name = "burgh"
	let shortDescription = "Generates and opens PR page"

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

	func execute() throws {
		guard
			let currentBranchName = try? capture(bash: "git rev-parse --abbrev-ref HEAD").stdout,
			let ticketId = TicketId(branchName: currentBranchName)
		else {
			stdout <<< Error.invalidBranchFormat.localizedDescription
			return
		}

		let repoShorthand = "asosteam/asos-native-ios"
		let accessTokenStore = AccessTokenStore()
		let accessTokenConfig: AccessTokenConfig

		if let config = accessTokenStore.config {
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
			accessTokenStore.config = accessTokenConfig
		}

		let repoInfoFetcher = GitHubRepositoryInfoFetcher(accessToken: accessTokenConfig.githubAccessToken)
		let ticketFetcher = TicketFetcher(email: accessTokenConfig.jiraEmail, apiToken: accessTokenConfig.jiraApiToken)

		let repoInfo = try repoInfoFetcher.fetchRepositoryInfo(withRepositoryShorthand: repoShorthand)
		let ticket = try ticketFetcher.fetchTicket(with: ticketId)

		let pullRequestURLFactory = PullRequestURLFactory(repositoryShorthand: repoShorthand)
		// TODO: fetch possible dependency branch from related tickets
		pullRequestURLFactory.baseBranch = baseBranch(forBranch: currentBranchName)
		pullRequestURLFactory.targetBranch = currentBranchName
		pullRequestURLFactory.title = "[\(ticket.key)] \(ticket.fields.summary)"

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
}
