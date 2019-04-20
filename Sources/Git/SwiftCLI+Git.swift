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
