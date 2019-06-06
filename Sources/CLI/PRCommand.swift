import Foundation
import SwiftCLI
import struct BadondeKit.Payload
import struct BadondeKit.Output
import func BadondeKit.trySafely
import Configuration
import Core
import Git
import GitHub
import Jira

class PRCommand: Command {
	let name = "pr"
	let shortDescription = "Creates a PR from the current branch"
	let dryRun = Flag("--dry-run", description: "Print generated PR details instead of creating it")

	let startDatePointer: UnsafeMutablePointer<Date>

	init(startDatePointer: UnsafeMutablePointer<Date>) {
		self.startDatePointer = startDatePointer
	}

	func execute() throws {
		Logger.step("Reading configuration")
		let repository = try Repository(atPath: FileManager.default.currentDirectoryPath)
		let projectPath = repository.topLevelPath
		let configuration = try DynamicConfiguration(prioritizedScopes: [.local(path: projectPath), .global])
		let githubAccessToken = try getOrPromptRawValue(forKeyPath: .githubAccessToken, in: configuration)
		let jiraEmail = try getOrPromptRawValue(forKeyPath: .jiraEmail, in: configuration)
		let jiraApiToken = try getOrPromptRawValue(forKeyPath: .jiraApiToken, in: configuration)
		let remote = try repository.remote(for: configuration)
		let repositoryShorthand = try remote.repositoryShorthand()

		try autopushIfNeeded(to: remote, configuration: configuration)

		// Reset start date because credentials might've been prompted
		// or autopush might've been performed and analytics data about
		// tool performance might be skewed as a result.
		startDatePointer.pointee = Date()

		Logger.step("Evaluating Badondefile.swift")
		let badondefileOutput = try BadondefileRunner(forRepositoryPath: repository.topLevelPath).run(
			with: Payload(
				git: .init(
					path: projectPath,
					shorthand: repositoryShorthand,
					headBranch: repository.currentBranch,
					remote: remote
				),
				github: .init(accessToken: githubAccessToken),
				jira: .init(email: jiraEmail, apiToken: jiraApiToken)
			),
			logCapture: { Logger.logBadondefileLog($0) },
			stderrCapture: { Logger.fail($0) }
		)

		guard !dryRun.value else {
			logBadondefileOutput(badondefileOutput)
			return
		}

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
		DispatchGroup().asyncExecuteAndWait(
			{
				guard
					!badondefileOutput.pullRequest.assignees.isEmpty ||
					!badondefileOutput.pullRequest.labels.isEmpty ||
					badondefileOutput.pullRequest.milestone != nil
				else {
					return
				}
				trySafely {
					_ = try issueAPI.edit(
						at: repositoryShorthand,
						issueNumber: pullRequest.number,
						assignees: badondefileOutput.pullRequest.assignees.nilIfEmpty,
						labels: badondefileOutput.pullRequest.labels.map { $0.name }.nilIfEmpty,
						milestone: badondefileOutput.pullRequest.milestone?.number
					)
				}
			},
			{
				guard !badondefileOutput.pullRequest.reviewers.isEmpty else {
					return
				}
				trySafely {
					_ = try pullRequestAPI.requestReviewers(
						at: repositoryShorthand,
						pullRequestNumber: pullRequest.number,
						reviewers: badondefileOutput.pullRequest.reviewers
					)
				}
			}
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
				PullRequest.AnalyticsReporter.Data(
					outputAnalyticsData: badondefileOutput.analyticsData,
					startDate: startDatePointer.pointee
				)
			)
		}
		#endif
	}

	func autopushIfNeeded(to remote: Remote, configuration: KeyValueInteractive) throws {
		let currentBranch = try Branch.current(atPath: "")

		if try currentBranch.isAhead(of: remote, atPath: "") {
			let isGitAutopushEnabled = try configuration.getValue(ofType: Bool.self, forKeyPath: .gitAutopush) == true
			if isGitAutopushEnabled {
				Logger.step("Local branch is ahead of remote, pushing changes now")
				try Git.Push.perform(remote: remote, branch: currentBranch, atPath: "")
			} else {
				Logger.info("Local branch is ahead of remote, please push your changes")
			}
		}
	}

	func logBadondefileOutput(_ output: Output) {
		Logger.succeed()
		let output = output.description
		let maxLineLength = output.description
			.components(separatedBy: "\n")
			.map { $0.count }
			.max()
		let separator = String(repeating: "=", count: maxLineLength ?? 80)
		print(["", "Output", separator, output, separator, ""].joined(separator: "\n"))
	}
}

extension Repository {
	func remote(for configuration: KeyValueInteractive) throws -> Remote {
		if let remoteName = try configuration.getValue(ofType: String.self, forKeyPath: .gitRemote) {
			guard let selectedRemote = remotes.first(where: { $0.name == remoteName }) else {
				throw PRCommand.Error.gitRemoteMissing(remoteName)
			}
			return selectedRemote
		} else {
			guard let selectedRemote = remotes.first else {
				throw PRCommand.Error.noGitRemotes
			}
			return selectedRemote
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
