import Foundation
@testable import BadondeCore

CommandLineTool().run(with: [BurghCommand().name] + CommandLine.arguments.dropFirst())
