import Danger

let danger = Danger()

SwiftLint.lint(inline: true, strict: true, lintAllFiles: true)

let allNonBuildSwiftFiles = danger.utils.exec(#"find $PWD -type f -iname "*.swift" | grep -v '.build'"#)
	.components(separatedBy: "\n")

for file in allNonBuildSwiftFiles {
	let fileContents = danger.utils.readFile(file)
	if fileContents.contains("//  Created by") {
		fail("Please remove this copyright header", file: file, line: 0)
	}
}

//(danger.git.modifiedFiles + danger.git.createdFiles)
//	.filter { $0.contains("Copyright") && $0.fileType == .swift }
//	.forEach { fail(message: "Please remove this copyright header", file: $0, line: 0) }
