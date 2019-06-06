import Foundation
import Git
import GitHub
import Jira

public final class Badonde {
	public init(
		ticketNumberDerivationStrategy: TicketNumberDerivationStrategy = .regex,
		baseBranchDerivationStrategy: BaseBranchDerivationStrategy = .defaultBranch
	) {
		let dsl: (git: GitDSL, github: GitHubDSL, jira: JiraDSL?) = trySafely {
			guard let payloadPath = CommandLine.arguments.first(where: { $0.hasPrefix(FileManager.default.temporaryDirectory.path) }) else {
				throw Error.payloadMissing
			}
			let data = try Data(contentsOf: URL(fileURLWithPath: payloadPath))
			payload = try JSONDecoder().decode(Payload.self, from: data)

			let repositoryShorthand = payload.git.shorthand
			let remote = payload.git.remote
			let headBranch = payload.git.headBranch
			var baseBranch: Branch!

			var gitDSL = try GitDSL(
				remote: remote,
				defaultBranch: payload.git.remote.defaultBranch(atPath: payload.git.path),
				currentBranch: headBranch,
				diff: []
			)
			var githubDSL = GitHubDSL(
				labels: [],
				milestones: [],
				openPullRequests: []
			)
			var jiraDSL: JiraDSL?

			Logger.step("Deriving base branch and fetching API data")
			DispatchGroup().asyncExecuteAndWait(
				{
					trySafely {
						baseBranch = try baseBranchDerivationStrategy.baseBranch(for: gitDSL)
						baseBranch.source = .remote(remote)

						gitDSL.diff = try [Diff](baseBranch: baseBranch, targetBranch: headBranch, atPath: payload.git.path)
					}
				},
				{
					trySafely {
						let labelAPI = Label.API(accessToken: payload.github.accessToken)
						githubDSL.labels = try labelAPI.allLabels(for: repositoryShorthand)
					}
				},
				{
					trySafely {
						let milestoneAPI = Milestone.API(accessToken: payload.github.accessToken)
						githubDSL.milestones = try milestoneAPI.getMilestones(for: repositoryShorthand)
					}
				},
				{
					trySafely {
						let pullRequestAPI = PullRequest.API(accessToken: payload.github.accessToken)
						githubDSL.openPullRequests = try pullRequestAPI.allPullRequests(for: repositoryShorthand, state: .open)
					}
				},
				{
					trySafely {
						guard let ticketKey = try ticketNumberDerivationStrategy.ticketKey(for: gitDSL) else {
							return
						}
						let jiraEmail = payload.jira.email
						let jiraApiToken = payload.jira.apiToken
						let ticketAPI = Ticket.API(email: jiraEmail, apiToken: jiraApiToken)
						let ticket = try ticketAPI.getTicket(with: ticketKey)
						jiraDSL = JiraDSL(ticket: ticket)
					}
				}
			)

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

			return (git: gitDSL, github: githubDSL, jira: jiraDSL)
		}

		self.git = dsl.git
		self.github = dsl.github
		self.jira = dsl.jira

		badonde = self

		atexit {
			trySafely {
				let outputPath = Output.path(forRepositoryPath: payload.git.path)
				try output.write(to: URL(fileURLWithPath: outputPath))
			}
		}
	}

	public var git: GitDSL
	public var github: GitHubDSL
	public var jira: JiraDSL?

	public var pullRequest: Output.PullRequest {
		return output.pullRequest
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
	public enum TicketNumberDerivationStrategy {
		enum Constant {
			static let regex = #"((?<!([A-Z]{1,10})-?)[A-Z]+-\d+)"#
		}

		case regex
		case custom((GitDSL) -> String?)

		func ticketKey(for git: GitDSL) throws -> Ticket.Key? {
			switch self {
			case .regex:
				guard
					let rawTicketKey = git.currentBranch.name.firstMatch(forRegex: Constant.regex, options: .caseInsensitive),
					let ticketKey = Ticket.Key(rawValue: rawTicketKey.uppercased())
				else {
					return nil
				}
				return ticketKey
			case .custom(let strategyClosure):
				guard let rawTicketKey = strategyClosure(git) else {
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
	public enum Error: LocalizedError {
		case invalidTicketNumberByCustomStrategy

		public var errorDescription: String? {
			switch self {
			case .invalidTicketNumberByCustomStrategy:
				return "The ticket number derived by custom strategy has invalid format"
			}
		}
	}
}

extension Badonde {
	public enum BaseBranchDerivationStrategy {
		case defaultBranch
		case commitProximity
		case custom((GitDSL) -> String)

		func baseBranch(for git: GitDSL) throws -> Branch {
			switch self {
			case .defaultBranch:
				return git.defaultBranch
			case .commitProximity:
				return try git.currentBranch.parent(for: git.remote, atPath: "")
			case .custom(let strategyClosure):
				return try Branch(name: strategyClosure(git), source: .local)
			}
		}
	}
}
