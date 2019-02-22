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

extension URL {
	static let jiraApiTokenUrl = URL(string: "https://id.atlassian.com/manage/api-tokens")!
	static let githubApiTokenUrl = URL(string: "https://github.com/settings/tokens")!
}

class BurghCommand: Command {

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

	func remoteBranch(withTicketId ticketId: String) -> String? {
		guard let remoteBranchesRaw = try? capture(bash: "git branch -r | grep \"\(ticketId)\"").stdout else {
			return nil
		}

		return remoteBranchesRaw
			.replacingOccurrences(of: "  ", with: "")
			.split(separator: "\n")
			.map { $0.replacingOccurrences(of: "origin/", with: "") }
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

	func diffIncludesFilename(baseBranch: String, targetBranch: String, containing word: String) -> Bool {
		guard let diff = try? capture(bash: "git diff \(baseBranch)..\(targetBranch)").stdout else {
			return false
		}
		return diff
			.split(separator: "\n")
			.filter { $0.hasPrefix("diff --git") }
			.contains(where: { $0.contains("\(word)") })
	}

	func diffIncludesFile(baseBranch: String, targetBranch: String, withContent content: String) -> Bool {
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

	func execute() throws {
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown throughout the codepath

		Logger.step("Deriving ticket id from current branch")
		guard let currentBranchName = try? capture(bash: "git rev-parse --abbrev-ref HEAD").stdout else {
			throw Error.noGitRepositoryFound
		}

		guard let ticketId = TicketId(branchName: currentBranchName) else {
			throw Error.invalidBranchFormat(currentBranchName)
		}

		Logger.step("Deriving repo shorthand from remote configuration")
		guard let repoShorthand = getRepositoryShorthand() else {
			throw Error.missingGitRemote
		}

		// Set PR base and target branches
		let pullRequestURLFactory = PullRequestURLFactory(repositoryShorthand: repoShorthand)

		// TODO: fetch possible dependency branch from related tickets?
		if let baseTicket = baseTicket.value {
			Logger.step("Deriving base branch for ticket \(baseTicket)")
			guard let ticketBranch = remoteBranch(withTicketId: baseTicket) else {
				throw Error.invalidBaseTicketId(baseTicket)
			}
			pullRequestURLFactory.baseBranch = ticketBranch
			pullRequestURLFactory.labels.append("DEPENDENT")
		} else {
			Logger.step("Deriving base branch for \(currentBranchName)")
			pullRequestURLFactory.baseBranch = baseBranch(forBranch: currentBranchName)
		}
		pullRequestURLFactory.targetBranch = currentBranchName

		// Fetch or prompt for JIRA and GitHub credentials
		Logger.step("Reading configuration")
		let configurationStore = ConfigurationStore()
		let configuration = try getOrPromptConfiguration(for: configurationStore)

		let repoInfoFetcher = GitHubRepositoryInfoFetcher(accessToken: configuration.githubAccessToken)
		let ticketFetcher = TicketFetcher(email: configuration.jiraEmail, apiToken: configuration.jiraApiToken)

		Logger.step("Fetching repo info for \(repoShorthand)")
		let repoInfo = try repoInfoFetcher.fetchRepositoryInfo(withRepositoryShorthand: repoShorthand)
		Logger.step("Fetching ticket info for \(ticketId)")
		let ticket = try ticketFetcher.fetchTicket(with: ticketId)

		// Set PR title
		let pullRequestTitle = "[\(ticket.key)] \(ticket.fields.summary)"
		Logger.step("Setting title to \(pullRequestTitle)")
		pullRequestURLFactory.title = pullRequestTitle

		// Set PR labels
		let repoLabels = repoInfo.labels.map { $0.name }

		// Append Bug label if ticket is a bug
		if ticket.fields.issueType.isBug {
			if let bugLabel = repoLabels.fuzzyMatch(word: "bug") {
				Logger.step("Setting bug label")
				pullRequestURLFactory.labels.append(bugLabel)
			}
		}

		if
			let baseBranch = pullRequestURLFactory.baseBranch,
			let targetBranch = pullRequestURLFactory.targetBranch
		{
			// Append UI tests label
			let shouldAttachUITestLabel = diffIncludesFilename(
				baseBranch: baseBranch,
				targetBranch: targetBranch,
				containing: "UITests"
			)

			if shouldAttachUITestLabel, let uiTestsLabel = repoLabels.fuzzyMatch(word: "ui tests") {
				Logger.step("Setting UI tests label")
				pullRequestURLFactory.labels.append(uiTestsLabel)
			}

			// Append unit tests label
			let shouldAttachUnitTestLabel = diffIncludesFile(
				baseBranch: baseBranch,
				targetBranch: targetBranch,
				withContent: "XCTestCase"
			)

			if shouldAttachUnitTestLabel, let unitTestsLabel = repoLabels.fuzzyMatch(word: "unit tests") {
				Logger.step("Setting unit tests label")
				pullRequestURLFactory.labels.append(unitTestsLabel)
			}
		}

		// Append ticket's epic label if similar name is found in repo labels
		if let epic = ticket.fields.epicSummary {
			if let epicLabel = repoLabels.fuzzyMatch(word: epic) {
				Logger.step("Setting epic label to \(epic)")
				pullRequestURLFactory.labels.append(epicLabel)
			}
		}

		// Set PR milestone from ticket fix version
		if
			let rawMilestone = ticket.fields.fixVersions.first?.name,
			!rawMilestone.isEmpty
		{
			let repoMilestones = repoInfo.milestones.map({ $0.title })
			if let milestone = repoMilestones.fuzzyMatch(word: rawMilestone) {
				Logger.step("Setting milestone to \(milestone)")
				pullRequestURLFactory.milestone = milestone
			}
		}

		guard let pullRequestURL = pullRequestURLFactory.url else {
			throw Error.invalidPullRequestURL
		}

		Logger.step("Opening PR page")
		try openURL(pullRequestURL)

		// Report PR data (production only)
		#if !DEBUG
		Logger.step("Reporting analytics data")
		guard
			let firebaseProjectId = configurationStore.additionalConfiguration?.firebaseProjectId,
			let firebaseSecretToken = configurationStore.additionalConfiguration?.firebaseSecretToken
		else {
			return
		}

		let reporter = PullRequestAnalyticsReporter(firebaseProjectId: firebaseProjectId, firebaseSecretToken: firebaseSecretToken)
		let analyticsData = PullRequestAnalyticsData(
			isDependent: pullRequestURLFactory.labels?.contains("DEPENDENT") == true,
			labelCount: pullRequestURLFactory.labels?.count ?? 0,
			hasMilestone: pullRequestURLFactory.milestone != nil
		)
		try reporter.report(analyticsData)
		#endif

		Logger.finish()
	}

	func getOrPromptConfiguration(for store: ConfigurationStore) throws -> Configuration {
		let configuration: Configuration

		if let config = store.configuration {
			configuration = config
		} else {
			Logger.info("Configuration not found, credentials required")
			let jiraEmailInput = Input.readLine(
				prompt: "Enter JIRA email address:",
				secure: false,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "'\(input)' is invalid; \(invalidInputReason)"
				}
			)
			#if !DEBUG
			openURL(.jiraApiTokenUrl, delay: 2)
			#endif
			let jiraApiTokenInput = Input.readLine(
				prompt: "Enter JIRA API token (generated at \(URL.jiraApiTokenUrl):",
				secure: true,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "Invalid token; \(invalidInputReason)"
				}
			)
			#if !DEBUG
			openURL(.githubApiTokenUrl, delay: 2)
			#endif
			let githubAccessTokenInput = Input.readLine(
				prompt: "Enter GitHub API token (generated at \(URL.githubApiTokenUrl):",
				secure: true,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "Invalid token; \(invalidInputReason)"
				}
			)
			configuration = Configuration(
				jiraEmail: jiraEmailInput,
				jiraApiToken: jiraApiTokenInput,
				githubAccessToken: githubAccessTokenInput
			)
			try store.setConfiguration(configuration)
		}

		return configuration
	}

	func openURL(_ url: URL) throws {
		try run(bash: "open \"\(url)\"")
	}

	func openURL(_ url: URL, delay: TimeInterval) {
		let queue = DispatchQueue(label: "badonde_delay_queue")
		queue.asyncAfter(deadline: .now() + delay) {
			_ = try? self.openURL(url)
		}
	}
}
