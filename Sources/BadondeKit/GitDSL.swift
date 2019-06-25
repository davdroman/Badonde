import Foundation
import Git

/// An object representing Badonde's current Git context.
public struct GitDSL {
	/// The repo's remote in use.
	public var remote: Remote
	/// The repo's default branch.
	public var defaultBranch: Branch
	/// The repo's currently checked out branch.
	public var currentBranch: Branch
	/// The diff between base and current branch.
	public var diff: [Diff]
}
