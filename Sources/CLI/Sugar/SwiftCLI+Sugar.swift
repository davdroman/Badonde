import Foundation
import SwiftCLI

func open(_ url: URL) throws {
	_ = try Task.capture(bash: "open \"\(url)\"")
}
