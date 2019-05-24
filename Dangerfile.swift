import Danger

let danger = Danger()

SwiftLint.lint(inline: true, strict: true, lintAllFiles: true)

let copyrightedFiles = (danger.git.modifiedFiles + danger.git.createdFiles)
	.lazy
	.filter { $0.fileType == .swift }
	.filter { danger.utils.readFile($0).contains("\n//  Created by") }

if !copyrightedFiles.isEmpty {
	let files = copyrightedFiles.map { "- " + $0 }
	let messageComponents = ["Please remove the copyright headers in these files:"] + files
	let message = messageComponents.joined(separator: "\n")
	fail(message)
}
