import Foundation

public protocol RemoteInteractor {
	func getAllRemotes() throws -> String
	func getURL(forRemote remote: String) throws -> String
}

public struct Remote: Equatable {
	public var name: String
	public var url: URL

	public init(name: String, url: URL) {
		self.name = name
		self.url = url
	}
}

extension Remote {
	public static func getAll(interactor: RemoteInteractor? = nil) throws -> [Remote] {
		let interactor = interactor ?? SwiftCLI()

		return try interactor.getAllRemotes()
			.split(separator: "\n")
			.map { String($0) }
			.compactMap { remoteName in
				guard let remoteURL = try? URL(string: interactor.getURL(forRemote: remoteName)) else {
					return nil
				}
				return Remote(name: remoteName, url: remoteURL)
			}
	}
}
