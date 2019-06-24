import Foundation
import GitHub

/// An object representing Badonde's current GitHub context.
public struct GitHubDSL {
	/// The GitHub user who's running Badonde.
	public var me: User!
	/// All available repo labels.
	public var labels: [Label]
	/// All active repo milestones.
	public var milestones: [Milestone]
	/// All open pull requests in the repo.
	public var openPullRequests: [PullRequest]
}
