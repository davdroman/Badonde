import Foundation
import SwiftCLI

func open(_ url: URL) throws {
	_ = try capture(bash: "open \"\(url)\"")
}
