import Foundation
import Git
import GitHub
import Jira

/// An object that represents Badonde's execution.
public final class Badonde {
	/// Git information fetched by Badonde.
	public var git: GitDSL
	/// GitHub information fetched by Badonde.
	public var github: GitHubDSL
	/// Jira information fetched by Badonde.
	public var jira: JiraDSL?

	/// The PR object at this point in the execution.
	public var pullRequest: Output.PullRequest {
		return output.pullRequest
	}

	/// Returns an instance of `Badonde` and kickstarts the execution by fetching
	/// Git, GitHub, and Jira information.
	///
	/// By default, Badonde sets the head and base branches for the PR in
	/// initialization time. The base branch is determined through the specified
	/// `BaseBranchDerivationStrategy`.
	///
	/// - Parameters:
	///   - ticketType: the ticket type and preferred strategy to derive it
	///     (defaults to `nil`).
	///   - baseBranchDerivationStrategy: the preferred strategy to derive the
	///     Git base branch for the PR (defaults to `.defaultBranch`).
	public init(
		ticketType: TicketType? = nil,
		baseBranchDerivationStrategy: BaseBranchDerivationStrategy = .defaultBranch
	) {
		enum TicketInfo {
			case jira(Jira.Ticket)
			case github(GitHub.Issue)

			var githubIssue: GitHub.Issue? {
				guard case let .github(issue) = self else {
					return nil
				}
				return issue
			}
		}

		let (gitDSL, githubDSL, ticketInfo) = trySafely { () -> (GitDSL, GitHubDSL, TicketInfo?) in
			guard let payloadPath = CommandLine.arguments.first(where: { $0.hasPrefix(FileManager.default.temporaryDirectory.path) }) else {
				throw Error.payloadMissing
			}
			let data = try Data(contentsOf: URL(fileURLWithPath: payloadPath))
			payload = try JSONDecoder().decode(Payload.self, from: data)

			let repositoryShorthand = payload.git.shorthand
			let remote = payload.git.remote
			let headBranch = payload.git.headBranch
			let defaultBranch = payload.git.defaultBranch
			let tags = try Tag.getAll(atPath: payload.git.path)

			let ((baseBranch, diff), me, labels, milestones, openPullRequests, ticketInfo) = DispatchGroup().asyncExecuteAndWait(
				{ () -> (Branch, [Diff]) in
					var baseBranch = try baseBranchDerivationStrategy.baseBranch(
						forDefaultBranch: defaultBranch,
						remote: remote,
						currentBranch: headBranch,
						repositoryPath: payload.git.path
					)
					baseBranch.source = .remote(remote)
					let diff = try [Diff](baseBranch: baseBranch, targetBranch: headBranch, atPath: payload.git.path)
					return (baseBranch, diff)
				},
				{ () -> User in
					let userAPI = User.API(accessToken: payload.github.accessToken)
					return try userAPI.authenticatedUser()
				},
				{ () -> [Label] in
					let labelAPI = Label.API(accessToken: payload.github.accessToken)
					return try labelAPI.allLabels(for: repositoryShorthand)
				},
				{ () -> [Milestone] in
					let milestoneAPI = Milestone.API(accessToken: payload.github.accessToken)
					return try milestoneAPI.getMilestones(for: repositoryShorthand)
				},
				{ () -> [PullRequest] in
					let pullRequestAPI = PullRequest.API(accessToken: payload.github.accessToken)
					return try pullRequestAPI.allPullRequests(for: repositoryShorthand, state: .open)
				},
				{ () -> TicketInfo? in
					switch ticketType {
					case let .jira(organization, strategy)?:
						guard let ticketKey = try strategy.ticketKey(forCurrentBranch: headBranch) else {
							Logger.warn("No JIRA ticket number found for branch")
							return nil
						}
						guard let jira = payload.jira else {
							Logger.failAndExit(
								"""
								JIRA is used in Badondefile, but credentials are not configured.
								Please run 'badonde init'.
								"""
							)
						}
						let ticketAPI = Ticket.API(organization: organization, email: jira.email, apiToken: jira.apiToken)
						let ticket = try ticketAPI.getTicket(with: ticketKey)
						return .jira(ticket)
					case .githubIssue(let strategy)?:
						guard
							let issueNumberRaw = try strategy.issueNumber(forCurrentBranch: headBranch),
							let issueNumber = Int(issueNumberRaw)
						else {
							Logger.warn("No GitHub Issue number found for branch")
							return nil
						}
						let issueAPI = Issue.API(accessToken: payload.github.accessToken)
						let issue = try issueAPI.get(at: repositoryShorthand, issueNumber: issueNumber)
						return .github(issue)
					case .none:
						return nil
					}
				}
			)

			let gitDSL = GitDSL(
				remote: remote,
				defaultBranch: defaultBranch,
				currentBranch: headBranch,
				diff: diff,
				tags: tags
			)

			let githubDSL = GitHubDSL(
				me: me,
				issue: ticketInfo?.githubIssue,
				labels: labels,
				milestones: milestones,
				openPullRequests: openPullRequests
			)

			output = Output(
				pullRequest: .init(
					issueNumber: nil,
					title: headBranch.name,
					headBranch: headBranch.name,
					baseBranch: baseBranch.name,
					body: nil,
					reviewers: [],
					assignees: [],
					labels: [],
					milestone: nil,
					isDraft: true
				),
				analyticsData: .init(info: [:])
			)

			return (gitDSL, githubDSL, ticketInfo)
		}

		self.git = gitDSL
		self.github = githubDSL

		switch ticketInfo {
		case .jira(let ticket)?:
			self.jira = JiraDSL(ticket: ticket)
		case .github?, .none:
			break
		}

		badonde = self

		atexit {
			trySafely {
				let outputPath = Output.path(forRepositoryPath: payload.git.path)
				try output.write(to: URL(fileURLWithPath: outputPath))
			}
		}
	}
}

var badonde: Badonde!

extension Badonde {
	enum Error {
		case payloadMissing
	}
}

extension Badonde.Error: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .payloadMissing:
			return "Payload missing"
		}
	}
}
