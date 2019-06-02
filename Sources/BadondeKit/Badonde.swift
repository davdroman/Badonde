import Foundation
import Git
import GitHub
import Jira

public final class Badonde {

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
