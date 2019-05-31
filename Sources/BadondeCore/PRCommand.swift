import Foundation
import struct BadondeKit.Payload
import SwiftCLI
import GitHub
import Git
import Jira
import Configuration

class PRCommand: Command {
	let name = "pr"
	let shortDescription = "Creates a PR from the current branch"
	let baseBranch = Key<String>("-b", "--base-branch", description: "The base branch to target to (or a term within it)")

	let startDate: Date

	init(startDate: Date) {
		self.startDate = startDate
	}

	func execute() throws {
		Logger.step("Reading configuration")
		let repository = try Repository()
		let projectPath = repository.topLevelPath
		let configuration = try DynamicConfiguration(prioritizedScopes: [.local(projectPath), .global])
		let githubAccessToken = try getOrPromptRawValue(forKeyPath: .githubAccessToken, in: configuration)
		let jiraEmail = try getOrPromptRawValue(forKeyPath: .jiraEmail, in: configuration)
		let jiraApiToken = try getOrPromptRawValue(forKeyPath: .jiraApiToken, in: configuration)
		let remote = try self.remote(for: projectPath, configuration: configuration)
		let repositoryShorthand = try remote.repositoryShorthand()

		try autopushIfNeeded(to: remote, configuration: configuration)

		let badondefileOutput = try BadondefileRunner(repository: repository).run(
			with: Payload(
				configuration: .init(
					git: .init(remote: remote),
					github: .init(accessToken: githubAccessToken),
					jira: .init(email: jiraEmail, apiToken: jiraApiToken)
				)
			)
		)

		let pullRequestAPI = PullRequest.API(accessToken: githubAccessToken)
		let issueAPI = Issue.API(accessToken: githubAccessToken)

		Logger.step("Creating PR")
		let pullRequest = try pullRequestAPI.createPullRequest(
			at: repositoryShorthand,
			title: badondefileOutput.pullRequest.title,
			headBranch: badondefileOutput.pullRequest.headBranch,
			baseBranch: badondefileOutput.pullRequest.baseBranch,
			body: badondefileOutput.pullRequest.body,
			isDraft: badondefileOutput.pullRequest.isDraft
		)

		Logger.step("Setting PR details")
		_ = try issueAPI.edit(
			at: repositoryShorthand,
			issueNumber: pullRequest.number,
			labels: badondefileOutput.pullRequest.labels?.map { $0.name },
			milestone: badondefileOutput.pullRequest.milestone?.number
		)

		try openURL(pullRequest.url)

		// Report PR data (production only)
		#if !DEBUG
		Logger.step("Reporting analytics data")
		if
			let firebaseProjectId = try configuration.getValue(ofType: String.self, forKeyPath: .firebaseProjectId),
			let firebaseSecretToken = try configuration.getValue(ofType: String.self, forKeyPath: .firebaseSecretToken)
		{
			let reporter = PullRequest.AnalyticsReporter(firebaseProjectId: firebaseProjectId, firebaseSecretToken: firebaseSecretToken)
			try reporter.report(
				PullRequest.analyticsData(
					isDependent: pullRequestBaseBranch.isTicketBranch,
					labelCount: pullRequestLabels.count,
					hasMilestone: pullRequestMilestone != nil,
					startDate: startDate
				)
			)
		}
		#endif
	}

	func remote(for url: URL, configuration: KeyValueInteractive) throws -> Remote {
		let allRemotes = try Remote.getAll()
		if let remoteName = try configuration.getValue(ofType: String.self, forKeyPath: .gitRemote) {
			guard let selectedRemote = allRemotes.first(where: { $0.name == remoteName }) else {
				throw Error.gitRemoteMissing(remoteName)
			}
			return selectedRemote
		} else {
			guard let selectedRemote = allRemotes.first else {
				throw Error.noGitRemotes
			}
			return selectedRemote
		}
	}

	func autopushIfNeeded(to remote: Remote, configuration: KeyValueInteractive) throws {
		let currentBranch = try Branch.current()

		if try currentBranch.isAhead(of: remote) {
			let isGitAutopushEnabled = try configuration.getValue(ofType: Bool.self, forKeyPath: .gitAutopush) == true
			if isGitAutopushEnabled {
				Logger.step("Local branch is ahead of remote, pushing changes now")
				try Git.Push.perform(remote: remote, branch: currentBranch)
			} else {
				Logger.info("Local branch is ahead of remote, please push your changes")
			}
		}
	}
}

extension PRCommand {
	enum Error {
		case gitRemoteMissing(String)
		case noGitRemotes
	}
}

extension PRCommand.Error: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .gitRemoteMissing(let remoteName):
			return "Git remote '\(remoteName)' is missing, please add it with `git remote add \(remoteName) [GIT_URL]`"
		case .noGitRemotes:
			return "Git remote is missing, please add it with `git remote add [REMOTE_NAME] [GIT_URL]`"
		}
	}
}
