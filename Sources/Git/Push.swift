import Foundation

protocol PushInteractor {
	func perform(remote: String, branch: String) throws
}

public enum Push { }

extension Push {
	static var interactor: PushInteractor = SwiftCLI()

	public static func perform(remote: Remote, branch: Branch) throws {
		try interactor.perform(remote: remote.name, branch: branch.name)
	}
}
