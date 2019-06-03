import Foundation
import Git
import GitHub
import Jira

public final class Badonde {
	public init(
		ticketNumberDerivationStrategy: TicketNumberDerivationStrategy,
		baseBranchDerivationStrategy: BaseBranchDerivationStrategy
	) {
		let dsl: (git: GitDSL, github: GitHubDSL, jira: JiraDSL?) = trySafely {
			let repository = try Repository()
			let branch = try Branch.current()

			let data = try Data(contentsOf: Payload.path(for: repository))
			let payload = try JSONDecoder().decode(Payload.self, from: data)

			let githubAccessToken = payload.configuration.github.accessToken
			let jiraEmail = payload.configuration.jira.email
			let jiraApiToken = payload.configuration.jira.apiToken

			let labelAPI = Label.API(accessToken: githubAccessToken)
			let milestoneAPI = Milestone.API(accessToken: githubAccessToken)
			let ticketAPI = Ticket.API(email: jiraEmail, apiToken: jiraApiToken)

			let gitDSL = try GitDSL(
				remote: payload.configuration.git.remote,
				defaultBranch: payload.configuration.git.remote.defaultBranch(),
				currentBranch: branch
			)

			let jiraDSL: JiraDSL?
			if let ticketKey = try ticketNumberDerivationStrategy.ticketKey(for: gitDSL) {
				let ticket = try ticketAPI.getTicket(with: ticketKey)
				jiraDSL = JiraDSL(ticket: ticket)
			} else {
				jiraDSL = nil
			}

			output = try Output(
				pullRequest: .init(
					title: jiraDSL?.ticket.key.rawValue ?? branch.name,
					headBranch: branch.name,
					baseBranch: baseBranchDerivationStrategy.baseBranch(for: gitDSL).name,
					body: nil,
					assignees: [],
					labels: [],
					milestone: nil,
					isDraft: true
				),
				analyticsData: .init(info: [:])
			)

			return (git: gitDSL, github: GitHubDSL(), jira: jiraDSL)
		}

		self.git = dsl.git
		self.github = dsl.github
		self.jira = dsl.jira

		saveOutputOnExit()
	}

	public var git: GitDSL
	public var github: GitHubDSL
	public var jira: JiraDSL?

	func saveOutputOnExit() {
		atexit {
			let repository = try! Repository()
			let outputPath = Output.path(for: repository)
			let outputData = try! JSONEncoder().encode(output)
			try! outputData.write(to: outputPath)
		}
	}
}

extension Badonde {
	public enum TicketNumberDerivationStrategy {
		enum Constant {
			static let regex = #"((?<!([A-Z]{1,10})-?)[A-Z]+-\d+)"#
		}

		public enum Error: Swift.Error {
			case invalidTicketNumberByCustomStrategy
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
				return try git.currentBranch.parent(for: git.remote)
			case .custom(let strategyClosure):
				return try Branch(name: strategyClosure(git), source: .local)
			}
		}
	}
}
