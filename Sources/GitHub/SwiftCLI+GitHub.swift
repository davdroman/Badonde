import Foundation
import SwiftCLI

final class SwiftCLI { }

extension SwiftCLI: RemoteInteractor {
	func repositoryShorthand(forRemote remote: String) throws -> String {
		return try capture(bash: "git remote show \(remote) -n | grep h.URL | sed 's/.*://;s/.git$//'").stdout
	}
}
