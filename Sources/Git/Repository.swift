import Foundation

public protocol RepositoryInteractor {
	func getTopLevelPath(from path: String) throws -> String
}

public struct Repository {
	public var topLevelPath: URL

	public init(path: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath), interactor: RepositoryInteractor? = nil) throws {
		let interactor = interactor ?? SwiftCLI()

		topLevelPath = try URL(fileURLWithPath: interactor.getTopLevelPath(from: path.path))
	}
}
