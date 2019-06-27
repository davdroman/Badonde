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
	///   - ticketNumberDerivationStrategy: the preferred strategy to derive the
	///     Jira ticket (defaults to `.regex`).
	///   - baseBranchDerivationStrategy: the preferred strategy to derive the
	///     Git base branch for the PR (defaults to `.defaultBranch`).
	public init(
		ticketNumberDerivationStrategy: TicketNumberDerivationStrategy = .regex,
		baseBranchDerivationStrategy: BaseBranchDerivationStrategy = .defaultBranch
	) {
		let (gitDSL, githubDSL, jiraDSL) = trySafely { () -> (GitDSL, GitHubDSL, JiraDSL?) in
			guard let payloadPath = CommandLine.arguments.first(where: { $0.hasPrefix(FileManager.default.temporaryDirectory.path) }) else {
				throw Error.payloadMissing
			}
			let data = try Data(contentsOf: URL(fileURLWithPath: payloadPath))
			payload = try JSONDecoder().decode(Payload.self, from: data)

			let repositoryShorthand = payload.git.shorthand
			let remote = payload.git.remote
			let headBranch = payload.git.headBranch
			let defaultBranch = try payload.git.remote.defaultBranch(atPath: payload.git.path)

			let ((baseBranch, diff), me, labels, milestones, openPullRequests, ticket) = DispatchGroup().asyncExecuteAndWait(
				{ () -> (Branch, [Diff]) in
					var baseBranch = try baseBranchDerivationStrategy.baseBranch(
						forDefaultBranch: defaultBranch,
						remote: remote,
						currentBranch: headBranch
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
				{ () -> Jira.Ticket? in
					guard let ticketKey = try ticketNumberDerivationStrategy.ticketKey(forCurrentBranch: headBranch) else {
						return nil
					}
					let jiraEmail = payload.jira.email
					let jiraApiToken = payload.jira.apiToken
					let ticketAPI = Ticket.API(email: jiraEmail, apiToken: jiraApiToken)
					return try ticketAPI.getTicket(with: ticketKey)
				}
			)

			let gitDSL = GitDSL(
				remote: remote,
				defaultBranch: defaultBranch,
				currentBranch: headBranch,
				diff: diff
			)

			let githubDSL = GitHubDSL(
				me: me,
				labels: labels,
				milestones: milestones,
				openPullRequests: openPullRequests
			)

			let jiraDSL: JiraDSL?

			if let ticket = ticket {
				jiraDSL = JiraDSL(ticket: ticket)
			} else {
				jiraDSL = nil
			}

			output = Output(
				pullRequest: .init(
					title: jiraDSL?.ticket.key.rawValue ?? headBranch.name,
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

			return (gitDSL, githubDSL, jiraDSL)
		}

		self.git = gitDSL
		self.github = githubDSL
		self.jira = jiraDSL

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

extension Badonde {
	/// Defines the way in which to derive a Jira ticket ID through the current Git
	/// context.
	public enum TicketNumberDerivationStrategy {
		enum Constant {
			static let regex = #"((?<!([A-Z]{1,10})-?)[A-Z]+-\d+)"#
		}

		/// Use the official Jira regular expression to match a ticket ID:
		/// `((?<!([A-Z]{1,10})-?)[A-Z]+-\d+)`
		case regex
		/// Use a user-provided custom function with the currently checked out branch
		/// name as a parameter to derive a ticket ID.
		///
		/// If `nil` is returned, the property `Badonde.jira` becomes `nil`.
		case custom((String) -> String?)

		func ticketKey(forCurrentBranch currentBranch: Branch) throws -> Ticket.Key? {
			switch self {
			case .regex:
				guard
					let rawTicketKey = currentBranch.name.firstMatch(forRegex: Constant.regex, options: .caseInsensitive),
					let ticketKey = Ticket.Key(rawValue: rawTicketKey.uppercased())
				else {
					return nil
				}
				return ticketKey
			case .custom(let strategyClosure):
				guard let rawTicketKey = strategyClosure(currentBranch.name) else {
					return nil
				}
				guard let ticketKey = Ticket.Key(rawValue: rawTicketKey) else {
					throw Error.invalidTicketNumberByCustomStrategy
				}
				return ticketKey
			}
		}
	}
}

extension Badonde.TicketNumberDerivationStrategy {
	enum Error: LocalizedError {
		case invalidTicketNumberByCustomStrategy

		var errorDescription: String? {
			switch self {
			case .invalidTicketNumberByCustomStrategy:
				return "The ticket number derived by custom strategy has invalid format"
			}
		}
	}
}

extension Badonde {
	/// Defines the way in which to derive the Git base branch of the PR through the
	/// current Git context.
	public enum BaseBranchDerivationStrategy {
		/// Use the default branch for the repo.
		case defaultBranch
		/// Use a derivation algorithm that compares how many commits away the current
		/// branch is from all other branches, and selects the one with the smallest
		/// non-zero amount.
		case commitProximity
		/// Use a user-provided custom function with the currently checked out branch
		/// name as a parameter to derive the base branch.
		case custom((String) -> String)

		func baseBranch(forDefaultBranch defaultBranch: Branch, remote: Remote, currentBranch: Branch) throws -> Branch {
			switch self {
			case .defaultBranch:
				return defaultBranch
			case .commitProximity:
				return try currentBranch.parent(for: remote, atPath: "")
			case .custom(let strategyClosure):
				return try Branch(name: strategyClosure(currentBranch.name), source: .local)
			}
		}
	}
}
