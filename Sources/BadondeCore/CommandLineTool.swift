import Foundation
import SwiftCLI

public final class CommandLineTool {
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    public func run() throws {
        let cli = CLI(singleCommand: BadondeCommand())
		_ = cli.go()
    }
}
