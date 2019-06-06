import Foundation

protocol RemoteInteractor {
	func getAllRemotes(atPath path: String) throws -> String
	func getURL(forRemote remote: String, atPath path: String) throws -> String
	func defaultBranch(forRemote remote: String, atPath path: String) throws -> String
}

public struct Remote: Equatable, Codable {
	public var name: String
	public var url: URL

	public init(name: String, url: URL) {
		self.name = name
		self.url = url
	}
}

extension Remote {
	static var interactor: RemoteInteractor = SwiftCLI()

	public static func getAll(atPath path: String) throws -> [Remote] {
		return try interactor.getAllRemotes(atPath: path)
			.components(separatedBy: "\n")
			.compactMap { remoteName in
				guard let remoteURL = try? URL(string: interactor.getURL(forRemote: remoteName, atPath: path)) else {
					return nil
				}
				return Remote(name: remoteName, url: remoteURL)
			}
	}

	public func defaultBranch(atPath path: String) throws -> Branch {
		return try Branch(
			name: Remote.interactor.defaultBranch(forRemote: name, atPath: path),
			source: .remote(self)
		)
	}
}
