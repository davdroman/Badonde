import Danger

let danger = Danger()

SwiftLint.lint(inline: true)

(danger.git.modifiedFiles + danger.git.createdFiles)
	.filter { $0.contains("Copyright") && $0.fileType == .swift }
	.forEach { fail(message: "Please remove this copyright header", file: $0, line: 0) }
