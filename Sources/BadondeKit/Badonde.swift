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
		let (gitDSL, githubDSL, jiraDSL) = trySafely { () -> (GitDSL, GitHubDSL, JiraDSL?) in
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

			let ((baseBranch, diff), me, labels, milestones, openPullRequests, (jiraTicket, githubIssue)) = DispatchGroup().asyncExecuteAndWait(
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
				{ () -> (Jira.Ticket?, GitHub.Issue?) in
					switch ticketType {
					case let .jira(organization, strategy)?:
						guard let ticketKey = try strategy.ticketKey(forCurrentBranch: headBranch) else {
							Logger.warn("No JIRA ticket number found for branch")
							return (nil, nil)
						}
						guard let jira = payload.jira else {
							failAndExit(
								"""
								JIRA is used in Badondefile, but credentials are not configured.
								Please run 'badonde init'.
								"""
							)
						}
						let ticketAPI = Ticket.API(organization: organization, email: jira.email, apiToken: jira.apiToken)
						let ticket = try ticketAPI.getTicket(with: ticketKey)
						return (ticket, nil)
					case .githubIssue(let strategy)?:
						guard
							let issueNumberRaw = try strategy.issueNumber(forCurrentBranch: headBranch),
							let issueNumber = Int(issueNumberRaw)
						else {
							Logger.warn("No GitHub Issue number found for branch")
							return (nil, nil)
						}
						let issueAPI = Issue.API(accessToken: payload.github.accessToken)
						let issue = try issueAPI.get(at: repositoryShorthand, issueNumber: issueNumber)
						return (nil, issue)
					case .none:
						return (nil, nil)
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
				issue: githubIssue,
				labels: labels,
				milestones: milestones,
				openPullRequests: openPullRequests
			)

			let jiraDSL = jiraTicket.map(JiraDSL.init(ticket:))

			output = Output(
				pullRequest: .init(
					issueNumber: nil,
					title: jiraDSL?.ticket.key.rawValue ?? githubDSL.issue?.title ?? headBranch.name,
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
	/// Defines a type of issue and how it's derived.
	public enum TicketType {
		/// Defines the way in which to derive a Jira ticket ID through the current Git
		/// context.
		public enum JiraDerivationStrategy {
			enum Constant {
				static let regex = #"((?<!([A-Z]{1,10})-?)[A-Z]+-\d+)"#
			}

			/// Use the official Jira regular expression to match a ticket ID:
			/// `((?<!([A-Z]{1,10})-?)[A-Z]+-\d+)`
			case regex
			/// Use a user-provided custom function with the currently checked out branch
			/// name as a parameter to derive the ticket ID.
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

		/// Defines the way in which to derive a GitHub Issue number through the current Git
		/// context.
		public enum GitHubIssueDerivationStrategy {
			enum Constant {
				static let regex = #"\d+"#
			}

			/// Match the first occurrence of a number in the current branch with regex
			/// `\d+`
			case regex
			/// Use a user-provided custom function with the currently checked out branch
			/// name as a parameter to derive the issue number.
			///
			/// If `nil` is returned, the property `Badonde.githubDSL.issue` becomes `nil`.
			case custom((String) -> String?)

			func issueNumber(forCurrentBranch currentBranch: Branch) throws -> String? {
				switch self {
				case .regex:
					return currentBranch.name.firstMatch(forRegex: Constant.regex, options: .caseInsensitive)
				case .custom(let strategyClosure):
					return strategyClosure(currentBranch.name)
				}
			}
		}

		/// A JIRA Issue.
		case jira(organization: String, derivationStrategy: JiraDerivationStrategy)
		/// A GitHub Issue.
		case githubIssue(derivationStrategy: GitHubIssueDerivationStrategy)
	}
}

extension Badonde.TicketType.JiraDerivationStrategy {
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
		/// Use the configured default branch for the repo (`git.defaultBranch`).
		case defaultBranch
		/// Use the specified branch by name.
		case branch(named: String)
		/// Use a derivation algorithm that compares how many commits away the current
		/// branch is from all other branches, and selects the one with the smallest
		/// non-zero amount.
		case commitProximity
		/// Use a user-provided custom function with the currently checked out branch
		/// name as a parameter to derive the base branch.
		case custom((String) -> String)

		func baseBranch(forDefaultBranch defaultBranch: Branch, remote: Remote, currentBranch: Branch, repositoryPath: String) throws -> Branch {
			switch self {
			case .defaultBranch:
				return defaultBranch
			case .branch(let name):
				return try Branch(name: name, source: .remote(remote))
			case .commitProximity:
				return try currentBranch.parent(for: remote, defaultBranch: defaultBranch, atPath: repositoryPath)
			case .custom(let strategyClosure):
				return try Branch(name: strategyClosure(currentBranch.name), source: .local)
			}
		}
	}
}
