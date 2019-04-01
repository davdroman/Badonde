import Foundation
import SwiftCLI
import GitHub
import Jira

extension URL {
	static let jiraApiTokenUrl = URL(string: "https://id.atlassian.com/manage/api-tokens")!
	static let githubApiTokenUrl = URL(string: "https://github.com/settings/tokens")!
}

class BurghCommand: Command {

	let name = "burgh"
	let shortDescription = "Generates and opens PR page"
	let baseBranch = Key<String>("-b", "--base-branch", description: "The base branch to target to (or a term within it)")

	func execute() throws {
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown along the way

		Logger.step("Deriving ticket id from current branch")
		guard let currentBranchName = try? capture(bash: "git rev-parse --abbrev-ref HEAD").stdout else {
			throw Error.noGitRepositoryFound
		}

		guard let ticketKey = Ticket.Key(branchName: currentBranchName) else {
			throw Error.invalidBranchFormat(currentBranchName)
		}

		guard ticketKey.rawValue != "NO-TICKET" else {
			throw Error.noTicketKey
		}

		Logger.step("Deriving repo shorthand from remote configuration")
		guard let repoShorthand = Git.getRepositoryShorthand() else {
			throw Error.missingGitRemote
		}

		// Fetch or prompt for JIRA and GitHub credentials
		Logger.step("Reading configuration")
		let configurationStore = ConfigurationStore()
		let configuration = try getOrPromptConfiguration(for: configurationStore)

		let labelAPI = Label.API(accessToken: configuration.githubAccessToken)
		let milestoneAPI = Milestone.API(accessToken: configuration.githubAccessToken)
		let repoAPI = Repository.API(accessToken: configuration.githubAccessToken)
		let ticketAPI = Ticket.API(email: configuration.jiraEmail, apiToken: configuration.jiraApiToken)

		// Set PR base and target branches
		let pullRequestURLFactory = PullRequestURLFactory(repositoryShorthand: repoShorthand)

		if let baseBranchValue = baseBranch.value {
			guard let baseBranch = Git.remoteBranch(containing: baseBranchValue) else {
				throw Error.invalidBaseBranch(baseBranchValue)
			}
			Logger.step("Using base branch '\(baseBranch)'")
			pullRequestURLFactory.baseBranch = baseBranch
		} else {
			Logger.step("Fetching repo default branch for '\(repoShorthand)'")
			let defaultBranch = try repoAPI.getRepository(with: repoShorthand).defaultBranch
			Logger.step("Deriving base branch by commit proximity")
			if let baseBranch = Git.closestBranch(to: currentBranchName, priorityBranch: defaultBranch) {
				Logger.step("Using base branch '\(baseBranch)'")
				pullRequestURLFactory.baseBranch = baseBranch
			} else {
				Logger.step("Using repo default branch '\(defaultBranch)'")
				pullRequestURLFactory.baseBranch = defaultBranch
			}
		}
		pullRequestURLFactory.targetBranch = currentBranchName

		Logger.step("Fetching ticket info for '\(ticketKey)'")
		let ticket = try ticketAPI.getTicket(with: ticketKey)

		// Set PR title
		let pullRequestTitle = "[\(ticket.key)] \(ticket.fields.summary)"
		Logger.step("Setting title to '\(pullRequestTitle)'")
		pullRequestURLFactory.title = pullRequestTitle

		Logger.step("Fetching repo labels for '\(repoShorthand)'")
		let labels = try labelAPI.getLabels(for: repoShorthand).map({ $0.name })

		// Append dependency label if base branch is another ticket
		if pullRequestURLFactory.baseBranch?.isTicketBranch == true {
			if let dependencyLabel = labels.fuzzyMatch(word: "depend") {
				Logger.step("Setting dependency label")
				pullRequestURLFactory.labels.append(dependencyLabel)
			}
		}

		// Append Bug label if ticket is a bug
		if ticket.fields.issueType.isBug {
			if let bugLabel = labels.fuzzyMatch(word: "bug") {
				Logger.step("Setting bug label")
				pullRequestURLFactory.labels.append(bugLabel)
			}
		}

		if
			let baseBranch = pullRequestURLFactory.baseBranch,
			let targetBranch = pullRequestURLFactory.targetBranch
		{
			// Append UI tests label
			let shouldAttachUITestLabel = Git.diffIncludesFilename(
				baseBranch: baseBranch,
				targetBranch: targetBranch,
				containing: "UITests"
			)

			if shouldAttachUITestLabel, let uiTestsLabel = labels.fuzzyMatch(word: "ui tests") {
				Logger.step("Setting UI tests label")
				pullRequestURLFactory.labels.append(uiTestsLabel)
			}

			// Append unit tests label
			let shouldAttachUnitTestLabel = Git.diffIncludesFile(
				baseBranch: baseBranch,
				targetBranch: targetBranch,
				withContent: ": XCTestCase {"
			)

			if shouldAttachUnitTestLabel, let unitTestsLabel = labels.fuzzyMatch(word: "unit tests") {
				Logger.step("Setting unit tests label")
				pullRequestURLFactory.labels.append(unitTestsLabel)
			}
		}

		// Append ticket's epic label if similar name is found in repo labels
		if let epic = ticket.fields.epicSummary {
			if let epicLabel = labels.fuzzyMatch(word: epic) {
				Logger.step("Setting epic label to '\(epicLabel)'")
				pullRequestURLFactory.labels.append(epicLabel)
			}
		}

		// Set PR milestone from ticket fix version
		if
			let rawMilestone = ticket.fields.fixVersions.first?.name,
			!rawMilestone.isEmpty
		{
			Logger.step("Fetching repo milestones for '\(repoShorthand)'")
			let milestones = try milestoneAPI.getMilestones(for: repoShorthand).map({ $0.title })
			if let milestone = milestones.fuzzyMatch(word: rawMilestone) {
				Logger.step("Setting milestone to '\(milestone)'")
				pullRequestURLFactory.milestone = milestone
			}
		}

		let pullRequestURL = try pullRequestURLFactory.url()

		Logger.step("Opening PR page")
		try openURL(pullRequestURL)

		// Report PR data (production only)
		#if !DEBUG
		Logger.step("Reporting analytics data")
		if
			let firebaseProjectId = configurationStore.additionalConfiguration?.firebaseProjectId,
			let firebaseSecretToken = configurationStore.additionalConfiguration?.firebaseSecretToken
		{
			let reporter = PullRequestAnalyticsReporter(firebaseProjectId: firebaseProjectId, firebaseSecretToken: firebaseSecretToken)
			let analyticsData = PullRequestAnalyticsData(
				isDependent: pullRequestURLFactory.labels?.contains("DEPENDENT") == true,
				labelCount: pullRequestURLFactory.labels?.count ?? 0,
				hasMilestone: pullRequestURLFactory.milestone != nil
			)
			try reporter.report(analyticsData)
		}
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
				prompt: "Enter JIRA API token (generated at '\(URL.jiraApiTokenUrl)':",
				secure: true,
				errorResponse: { input, invalidInputReason in
					self.stderr <<< "Invalid token; \(invalidInputReason)"
				}
			)
			#if !DEBUG
			openURL(.githubApiTokenUrl, delay: 2)
			#endif
			let githubAccessTokenInput = Input.readLine(
				prompt: "Enter GitHub API token (generated at '\(URL.githubApiTokenUrl)':",
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
