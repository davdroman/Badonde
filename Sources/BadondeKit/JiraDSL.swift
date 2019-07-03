import Foundation
import Jira

/// An object representing Badonde's current Jira context.
public struct JiraDSL {
	/// The Jira ticket for the current branch.
	public var ticket: Ticket
}
