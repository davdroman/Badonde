import Foundation
import SwiftCLI

final class SwiftCLI { }

extension SwiftCLI: RemoteInteractor {
	func getAllRemotes() throws -> String {
		return try capture(bash: "git remote").stdout
	}

	func getURL(forRemote remote: String) throws -> String {
		return try capture(bash: "git remote get-url \(remote)").stdout
	}
}

extension SwiftCLI: BranchInteractor {
	func getAllBranches(from source: Branch.Source) throws -> String {
		switch source {
		case .local:
			return try capture(bash: "git branch | cut -c 3-").stdout
		case .remote(let remoteName):
			return try capture(bash: "git branch -r | grep '\(remoteName)/' | cut -c 3-").stdout
		}
	}
}
