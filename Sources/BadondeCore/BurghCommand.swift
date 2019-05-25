import Foundation
import SwiftCLI
import GitHub
import Git
import Jira
import Configuration

class BurghCommand: Command {
	let name = "burgh"
	let shortDescription = "Generates and opens PR page"
	let baseBranch = Key<String>("-b", "--base-branch", description: "The base branch to target to (or a term within it)")

	let startDate: Date

	init(startDate: Date) {
		self.startDate = startDate
	}

	func execute() throws {
		Logger.step("Reading configuration")
		let projectPath = try Repository().topLevelPath
		let configuration = try DynamicConfiguration(prioritizedScopes: [.local(projectPath), .global])
		let githubAccessToken = try getOrPromptRawValue(forKeyPath: .githubAccessToken, in: configuration)
		let jiraEmail = try getOrPromptRawValue(forKeyPath: .jiraEmail, in: configuration)
		let jiraApiToken = try getOrPromptRawValue(forKeyPath: .jiraApiToken, in: configuration)

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
				Logger.info("Local branch is ahead of remote, please push your changes")
			}
		}

		Logger.step("Deriving repo shorthand from remote")
		let repositoryShorthand = try remote.repositoryShorthand()

		let labelAPI = Label.API(accessToken: githubAccessToken)
		let milestoneAPI = Milestone.API(accessToken: githubAccessToken)
		let ticketAPI = Ticket.API(email: jiraEmail, apiToken: jiraApiToken)

		// Set up PR properties to be assigned
		let pullRequestBaseBranch: String
		let pullRequestHeadBranch: String
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
		pullRequestHeadBranch = currentBranch.name

		Logger.step("Fetching ticket info for '\(ticketKey)'")
		let ticket = try ticketAPI.getTicket(with: ticketKey)

		// Set PR title
		pullRequestTitle = "[\(ticket.key)] \(ticket.fields.summary)"
		Logger.step("Title set to '\(pullRequestTitle)'")

		Logger.step("Fetching repo labels for '\(repositoryShorthand)'")
		let labels = try labelAPI.getLabels(for: repositoryShorthand).map { $0.name }

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
		let addedFiles = diffs.compactMap { $0.addedFilePath }

		// Append UI tests label
		let shouldAttachUITestLabel = addedFiles.contains { $0.contains("UITests") }
		if shouldAttachUITestLabel, let uiTestsLabel = labels.fuzzyMatch(word: "ui tests") {
			Logger.step("Setting UI tests label")
			pullRequestLabels.append(uiTestsLabel)
		}

		// Append unit tests label
		let shouldAttachUnitTestLabel = try addedFiles.contains { try String(contentsOfFile: $0).contains(": XCTestCase {") }
		if shouldAttachUnitTestLabel, let unitTestsLabel = labels.fuzzyMatch(word: "unit tests") {
			Logger.step("Setting unit tests label")
			pullRequestLabels.append(unitTestsLabel)
		}

		// Append feature toggle label
		let shouldAttachFeatureToggleLabel = try addedFiles.contains { try String(contentsOfFile: $0).contains("enum Feature:") }
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
			let milestones = try milestoneAPI.getMilestones(for: repositoryShorthand).map { $0.title }
			if let milestone = milestones.fuzzyMatch(word: rawMilestone) {
				Logger.step("Setting milestone to '\(milestone)'")
				pullRequestMilestone = milestone
			}
		}

		Logger.step("Opening PR page")
		let pullRequest = PullRequest(
			repositoryShorthand: repositoryShorthand,
			baseBranch: pullRequestBaseBranch,
			headBranch: pullRequestHeadBranch,
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
	}
}

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
