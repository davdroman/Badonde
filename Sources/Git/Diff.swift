import Foundation

public struct Diff: Equatable, CustomStringConvertible {
	public var addedFile: String
	public var removedFile: String
	public var hunks: [Hunk]

	public init(rawDiffContent: String) throws {
		let parsingResults = try Diff.Parser(rawDiffContent: rawDiffContent).parse()
		self.init(
			addedFile: parsingResults.addedFile,
			removedFile: parsingResults.removedFile,
			hunks: parsingResults.hunks
		)
	}

	init(addedFile: String, removedFile: String, hunks: [Hunk]) {
		self.addedFile = addedFile
		self.removedFile = removedFile
		self.hunks = hunks
	}

	public var description: String {
		let header = """
		--- \(removedFile)
		+++ \(addedFile)
		"""
		return hunks.reduce(into: header) {
			$0 += "\n\($1.description)"
		}
	}
}

extension Diff {
	public struct Hunk: Equatable, CustomStringConvertible {
		public var oldLineStart: Int
		public var oldLineSpan: Int
		public var newLineStart: Int
		public var newLineSpan: Int
		public var lines: [Line]

		public var description: String {
			let header = "@@ -\(oldLineStart),\(oldLineSpan) +\(newLineStart),\(newLineSpan) @@"
			return lines.reduce(into: header) {
				$0 += "\n\($1.description)"
			}
		}

		init(oldLineStart: Int, oldLineSpan: Int, newLineStart: Int, newLineSpan: Int, lines: [Line]) {
			self.oldLineStart = oldLineStart
			self.oldLineSpan = oldLineSpan
			self.newLineStart = newLineStart
			self.newLineSpan = newLineSpan
			self.lines = lines
		}
	}
}

extension Diff.Hunk {
	public struct Line: Equatable, CustomStringConvertible {
		public enum Kind: Equatable {
			case unchanged
			case addition
			case deletion
		}

		public var kind: Kind
		public var text: String

		public var description: String {
			switch kind {
			case .addition:
				return "+\(text)"
			case .deletion:
				return "-\(text)"
			case .unchanged:
				return " \(text)"
			}
		}

		init(type: Kind, text: String) {
			self.kind = type
			self.text = text
		}
	}
}

extension Array where Element == Diff {
	public init(rawDiffContent: String) throws {
		self = try rawDiffContent
			.components(separatedBy: "diff --git ")
			.filter { !$0.isEmpty }
			.map { try Diff(rawDiffContent: $0) }
	}
}
