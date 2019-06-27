import Foundation
import Git
import GitHub
import Jira

extension Badonde {
	@available(*, deprecated, message: "Use 'init(ticketType:baseBranchDerivationStrategy:)' instead")
	public convenience init(
		ticketNumberDerivationStrategy: TicketNumberDerivationStrategy,
		baseBranchDerivationStrategy: BaseBranchDerivationStrategy = .defaultBranch
	) {
		self.init(
			ticketType: TicketType(jiraTicketNumberDerivationStrategy: ticketNumberDerivationStrategy),
			baseBranchDerivationStrategy: baseBranchDerivationStrategy
		)
	}
}

extension Badonde {
	/// Defines the way in which to derive a Jira ticket ID through the current Git
	/// context.
	public enum TicketNumberDerivationStrategy {
		/// Use the official Jira regular expression to match a ticket ID:
		/// `((?<!([A-Z]{1,10})-?)[A-Z]+-\d+)`
		case regex
		/// Use a user-provided custom function with the currently checked out branch
		/// name as a parameter to derive a ticket ID.
		///
		/// If `nil` is returned, the property `Badonde.jira` becomes `nil`.
		case custom((String) -> String?)
	}
}

extension Badonde.TicketType {
	init(jiraTicketNumberDerivationStrategy strategy: Badonde.TicketNumberDerivationStrategy) {
		switch strategy {
		case .regex:
			self = .jira(derivationStrategy: .regex)
		case .custom(let closure):
			self = .jira(derivationStrategy: .custom(closure))
		}
	}
}
