import Danger

let danger = Danger()

SwiftLint.lint(inline: true, strict: true, lintAllFiles: true)

danger.utils.exec(#"find $PWD -type f -iname "*.swift" | grep -v '.build'"#)
	.components(separatedBy: "\n")
	.filter { !$0.isEmpty }
	.map { (file: $0, contents: danger.utils.readFile($0)) }
	.filter { $0.contents.contains("//  Created by") }
	.forEach { fail(message: "Please remove this copyright header", file: $0.file, line: 0) }

//(danger.git.modifiedFiles + danger.git.createdFiles)
//	.filter { $0.contains("Copyright") && $0.fileType == .swift }
//	.forEach { fail(message: "Please remove this copyright header", file: $0, line: 0) }
