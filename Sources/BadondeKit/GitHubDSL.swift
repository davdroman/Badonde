import Foundation
import GitHub

public struct GitHubDSL {
	public var me: User!
	public var labels: [Label]
	public var milestones: [Milestone]
	public var openPullRequests: [PullRequest]
}
