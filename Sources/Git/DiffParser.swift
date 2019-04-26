import Foundation

extension Diff {
	final class Parser {
		/// Regex for parsing git diffs.
		///
		/// - Group 1: The header old file line start.
		/// - Group 2: The header old file line span. If not present it defaults to 1.
		/// - Group 3: The header new file line start.
		/// - Group 4: The header new file line span. If not present it defaults to 1.
		/// - Group 5: The change delta, either "+", "-" or " ".
		/// - Group 6: The line itself.
		let regex = try! NSRegularExpression(
			pattern: "^(?:(?:@@ -(\\d+),?(\\d+)? \\+(\\d+),?(\\d+)? @@)|([-+\\s])(.*))",
			options: []
		)

		let rawDiffContent: String

		init(rawDiffContent: String) {
			self.rawDiffContent = rawDiffContent
		}

		func parse() throws -> (addedFile: String, removedFile: String, hunks: [Hunk]) {
			var addedFile: String?
			var removedFile: String?

			var hunks: [Hunk] = []
			var currentHunk: Hunk?

			for line in rawDiffContent.components(separatedBy: "\n") {
				// Skip headers
				guard !line.starts(with: "+++ ") else {
					addedFile = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
					continue
				}
				guard !line.starts(with: "--- ") else {
					removedFile = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
					continue
				}

				if let match = self.regex.firstMatch(in: line, options: [], range: NSMakeRange(0, line.utf16.count)) {
					if
						let oldLineStartString = match.group(1, in: line), let oldLineStart = Int(oldLineStartString),
						let newLineStartString = match.group(3, in: line), let newLineStart = Int(newLineStartString)
					{
						// Get the line spans. If not present default to 1.
						let oldLineSpan = match.group(2, in: line).flatMap { oldLineSpanString in Int(oldLineSpanString) } ?? 1
						let newLineSpan = match.group(4, in: line).flatMap { newLineSpanString in Int(newLineSpanString) } ?? 1

						if let currentHunk = currentHunk {
							hunks.append(currentHunk)
						}

						currentHunk = Hunk(
							oldLineStart: oldLineStart,
							oldLineSpan: oldLineSpan,
							newLineStart: newLineStart,
							newLineSpan: newLineSpan,
							lines: []
						)
					} else if
						let delta = match.group(5, in: line),
						let text = match.group(6, in: line)
					{
						guard var hunk = currentHunk else {
							throw Error.hunkHeaderMissing
						}

						let lineType: Diff.Hunk.Line.Kind
						switch delta {
						case "-":
							lineType = .deletion
						case "+":
							lineType = .addition
						case " ":
							lineType = .unchanged
						default:
							// Will never happen if the regex remains unchanged
							fatalError("Unexpected group 2 character: \(delta)")
						}

						hunk.lines.append(Diff.Hunk.Line(type: lineType, text: text))
						currentHunk = hunk
					}
				}
			}

			// Append last hunk
			if let currentHunk = currentHunk {
				hunks.append(currentHunk)
			}

			guard let added = addedFile, let removed = removedFile else {
				throw Error.filePathsNotFound
			}

			return (addedFile: added, removedFile: removed, hunks: hunks)
		}
	}
}

extension NSTextCheckingResult {
	func group(_ group: Int, in string: String) -> String? {
		let nsRange = range(at: group)
		if range.location != NSNotFound {
			return Range(nsRange, in: string).map { range in String(string[range]) }
		}
		return nil
	}
}

