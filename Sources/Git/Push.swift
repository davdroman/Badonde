import Foundation

public protocol PushInteractor {
	func perform(remote: String, branch: String) throws
}

public enum Push { }

extension Push {
	public static func perform(remote: Remote, branch: Branch, interactor: PushInteractor? = nil) throws {
		let interactor = interactor ?? SwiftCLI()
		try interactor.perform(remote: remote.name, branch: branch.name)
	}
}
