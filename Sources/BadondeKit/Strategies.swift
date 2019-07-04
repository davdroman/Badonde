import Foundation
import Git
import GitHub
import Jira

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
