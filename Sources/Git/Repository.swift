import Foundation

protocol RepositoryInteractor {
	func getTopLevelPath(forPath path: String) throws -> String
}

public struct Repository {
	static var interactor: RepositoryInteractor = SwiftCLI()

	public var topLevelPath: String
	public var currentBranch: Branch
	public var remotes: [Remote]

	public init(atPath path: String) throws {
		topLevelPath = try Repository.interactor.getTopLevelPath(forPath: path)
		currentBranch = try Branch.current(atPath: path)
		remotes = try Remote.getAll(atPath: path)
	}
}
