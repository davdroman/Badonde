import Foundation
import SwiftCLI
import GitHub
import Git
import Jira
import Configuration

extension URL {
	static let jiraApiTokenUrl = URL(string: "https://id.atlassian.com/manage/api-tokens")!
	static let githubApiTokenUrl = URL(string: "https://github.com/settings/tokens")!
}

class BurghCommand: Command {

	let name = "burgh"
	let shortDescription = "Generates and opens PR page"
	let baseBranch = Key<String>("-b", "--base-branch", description: "The base branch to target to (or a term within it)")

	let startDate: Date

	init(startDate: Date) {
		self.startDate = startDate
	}

	func execute() throws {
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown along the way

		Logger.step("Reading configuration")
		let projectPath = try Repository().topLevelPath
		let configuration = try DynamicConfiguration(prioritizedScopes: [.local(projectPath), .global])

		let allRemotes = try Remote.getAll()
		let remote: Remote
		if let remoteName = try configuration.getValue(ofType: String.self, forKeyPath: .gitRemote) {
			guard let selectedRemote = allRemotes.first(where: { $0.name == remoteName }) else {
				throw Error.gitRemoteMissing(remoteName)
			}
			remote = selectedRemote
		} else {
			guard let selectedRemote = allRemotes.first else {
				throw Error.noGitRemotes
			}
			remote = selectedRemote
		}

		let currentBranch = try Branch.current()

		Logger.step("Deriving ticket id from current branch")
		guard let ticketKey = Ticket.Key(branchName: currentBranch.name) else {
			throw Error.invalidBranchFormat(currentBranch.name)
		}

		guard ticketKey.rawValue != "NO-TICKET" else {
			throw Error.noTicketKey
		}

		if try currentBranch.isAhead(of: remote) {
			let isGitAutopushEnabled = try configuration.getValue(ofType: Bool.self, forKeyPath: .gitAutopush) == true
			if isGitAutopushEnabled {
				Logger.step("Local branch is ahead of remote, pushing changes now")
				try Git.Push.perform(remote: remote, branch: currentBranch)
			} else {
				Logger.succeed()
				Logger.info("Local branch is ahead of remote, please push your changes")
			}
		}

		Logger.step("Deriving repo shorthand from remote")
		let repositoryShorthand = try remote.repositoryShorthand()

		// Fetch or prompt for JIRA and GitHub credentials
		let githubAccessToken = try getOrPromptRawValue(forKeyPath: .githubAccessToken, in: configuration)
		let jiraEmail = try getOrPromptRawValue(forKeyPath: .jiraEmail, in: configuration)
		let jiraApiToken = try getOrPromptRawValue(forKeyPath: .jiraApiToken, in: configuration)

		let labelAPI = Label.API(accessToken: githubAccessToken)
		let milestoneAPI = Milestone.API(accessToken: githubAccessToken)
		let ticketAPI = Ticket.API(email: jiraEmail, apiToken: jiraApiToken)

		// Set up PR properties to be assigned
		let pullRequestBaseBranch: String
		let pullRequestTargetBranch: String
		let pullRequestTitle: String
		var pullRequestLabels: [String] = []
		var pullRequestMilestone: String?

		// Set PR base and target branches
		if let baseBranchValue = baseBranch.value {
			let allRemoteBranches = try Branch.getAll(from: .remote(remote))
			guard let baseBranch = allRemoteBranches.first(where: { $0.name.contains(baseBranchValue) }) else {
				throw Error.invalidBaseBranch(baseBranchValue)
			}
			Logger.step("Using base branch '\(baseBranch)'")
			pullRequestBaseBranch = baseBranch.name
		} else {
			Logger.step("Deriving base branch by commit proximity")
			let baseBranch = try currentBranch.parent(for: remote)
			Logger.step("Using base branch '\(baseBranch.name)'")
			pullRequestBaseBranch = baseBranch.name
		}
		pullRequestTargetBranch = currentBranch.name

		Logger.step("Fetching ticket info for '\(ticketKey)'")
		let ticket = try ticketAPI.getTicket(with: ticketKey)

		// Set PR title
		pullRequestTitle = "[\(ticket.key)] \(ticket.fields.summary)"
		Logger.step("Title set to '\(pullRequestTitle)'")

		Logger.step("Fetching repo labels for '\(repositoryShorthand)'")
		let labels = try labelAPI.getLabels(for: repositoryShorthand).map({ $0.name })

		// Append dependency label if base branch is another ticket
		if pullRequestBaseBranch.isTicketBranch {
			if let dependencyLabel = labels.fuzzyMatch(word: "depend") {
				Logger.step("Setting dependency label")
				pullRequestLabels.append(dependencyLabel)
			}
		}

		// Append Bug label if ticket is a bug
		if ticket.fields.issueType.isBug {
			if let bugLabel = labels.fuzzyMatch(word: "bug") {
				Logger.step("Setting bug label")
				pullRequestLabels.append(bugLabel)
			}
		}

		Logger.step("Diffing base and target for label derivation")
		let diffs = try [Diff](baseBranch: Branch(name: pullRequestBaseBranch, source: .remote(remote)), targetBranch: currentBranch)

		// Append UI tests label
		let shouldAttachUITestLabel = diffs.contains(where: { $0.addedFilePath.contains("UITests") })
		if shouldAttachUITestLabel, let uiTestsLabel = labels.fuzzyMatch(word: "ui tests") {
			Logger.step("Setting UI tests label")
			pullRequestLabels.append(uiTestsLabel)
		}

		// Append unit tests label
		let shouldAttachUnitTestLabel = try diffs.contains(where: { try String(contentsOfFile: $0.addedFilePath).contains(": XCTestCase {") })
		if shouldAttachUnitTestLabel, let unitTestsLabel = labels.fuzzyMatch(word: "unit tests") {
			Logger.step("Setting unit tests label")
			pullRequestLabels.append(unitTestsLabel)
		}

		// Append feature toggle label
		let shouldAttachFeatureToggleLabel = try diffs.contains(where: { try String(contentsOfFile: $0.addedFilePath).contains("enum Feature:") })
		if shouldAttachFeatureToggleLabel, let featureToggleLabel = labels.fuzzyMatch(word: "feature toggle") {
			Logger.step("Setting feature toggle label")
			pullRequestLabels.append(featureToggleLabel)
		}

		// Append ticket's epic label if similar name is found in repo labels
		if let epic = ticket.fields.epicSummary {
			if let epicLabel = labels.fuzzyMatch(word: epic) {
				Logger.step("Setting epic label to '\(epicLabel)'")
				pullRequestLabels.append(epicLabel)
			}
		}

		// Set PR milestone from ticket fix version
		if
			let rawMilestone = ticket.fields.fixVersions.first?.name,
			!rawMilestone.isEmpty
		{
			Logger.step("Fetching repo milestones for '\(repositoryShorthand)'")
			let milestones = try milestoneAPI.getMilestones(for: repositoryShorthand).map({ $0.title })
			if let milestone = milestones.fuzzyMatch(word: rawMilestone) {
				Logger.step("Setting milestone to '\(milestone)'")
				pullRequestMilestone = milestone
			}
		}

		Logger.step("Opening PR page")
		let pullRequest = PullRequest(
			repositoryShorthand: repositoryShorthand,
			baseBranch: pullRequestBaseBranch,
			targetBranch: pullRequestTargetBranch,
			title: pullRequestTitle,
			labels: pullRequestLabels,
			milestone: pullRequestMilestone
		)
		try openURL(pullRequest.url())

		// Report PR data (production only)
		#if !DEBUG
		Logger.step("Reporting analytics data")
		if
			let firebaseProjectId = try configuration.getValue(ofType: String.self, forKeyPath: .firebaseProjectId),
			let firebaseSecretToken = try configuration.getValue(ofType: String.self, forKeyPath: .firebaseSecretToken)
		{
			let reporter = PullRequest.AnalyticsReporter(firebaseProjectId: firebaseProjectId, firebaseSecretToken: firebaseSecretToken)
			try reporter.report(pullRequest.analyticsData(startDate: startDate))
		}
		#endif

		Logger.finish()
	}
}
