import Danger

let danger = Danger()

SwiftLint.lint(inline: true, strict: true, lintAllFiles: true)

(danger.git.modifiedFiles + danger.git.createdFiles)
	.filter { $0.fileType == .swift }
	.map { (file: $0, contents: danger.utils.readFile($0)) }
	.filter { $0.contents.contains("\n//  Created by") }
	.forEach { fail(message: "Please remove this copyright header", file: $0.file, line: 0) }
