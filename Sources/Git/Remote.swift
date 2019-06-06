import Foundation

protocol RemoteInteractor {
	func getAllRemotes() throws -> String
	func getURL(forRemote remote: String) throws -> String
	func defaultBranch(forRemote remote: String) throws -> String
}

public struct Remote: Codable, Equatable {
	public var name: String
	public var url: URL

	public init(name: String, url: URL) {
		self.name = name
		self.url = url
	}
}

extension Remote {
	static var interactor: RemoteInteractor = SwiftCLI()

	public static func getAll() throws -> [Remote] {
		return try interactor.getAllRemotes()
			.components(separatedBy: "\n")
			.compactMap { remoteName in
				guard let remoteURL = try? URL(string: interactor.getURL(forRemote: remoteName)) else {
					return nil
				}
				return Remote(name: remoteName, url: remoteURL)
			}
	}

	public func defaultBranch() throws -> Branch {
		return try Branch(
			name: Remote.interactor.defaultBranch(forRemote: name),
			source: .remote(self)
		)
	}
}
