import Foundation

protocol RepositoryInteractor {
	func getTopLevelPath(from path: String) throws -> String
}

public struct Repository {
	static var interactor: RepositoryInteractor = SwiftCLI()

	public var topLevelPath: URL

	public init(path: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) throws {
		topLevelPath = try URL(fileURLWithPath: Repository.interactor.getTopLevelPath(from: path.path))
	}
}
