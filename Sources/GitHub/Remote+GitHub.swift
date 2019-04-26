import Foundation
import Git

public protocol RemoteInteractor {
	func repositoryShorthand(forRemote remote: String) throws -> String
}

extension Remote {
	public func repositoryShorthand(interactor: RemoteInteractor? = nil) throws -> Repository.Shorthand {
		let interactor = interactor ?? SwiftCLI()

		let rawRepositoryShorthand = try interactor.repositoryShorthand(forRemote: name)
		guard let shorthand = Repository.Shorthand(rawValue: rawRepositoryShorthand) else {
			throw Repository.Shorthand.Error.parsing
		}
		return shorthand
	}
}
