import XCTest
@testable import Git
import TestSugar

final class DiffInteractorMock: DiffInteractor {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "diff" }

		case baseMasterTargetDevelop = "base_master_target_develop" // single diff
		case baseReleaseTargetDevelop = "base_release_target_develop" // multi-diff
	}

	func diff(baseBranch: String, targetBranch: String) throws -> String {
		return try Fixture(rawValue: "base_\(baseBranch)_target_\(targetBranch)")!.load(as: String.self)
	}
}

final class DiffTests: XCTestCase {
	enum Fixture: String, FixtureLoadable {
		var sourceFilePath: String { return #file }
		var fixtureFileExtension: String { return "diff" }

		case noNewLine = "no_new_line"
		case newFileMode = "new_file_mode"
		case renamedFileMode = "renamed_file_mode"
		case deletedFileMode = "deleted_file_mode"
		case multiFileChange = "multi_file_change"

		case hunkHeaderMissing = "hunk_header_missing"
		case addedFileMissing = "added_file_missing"
	}

	func testInit_noNewline() throws {
		let diffFileContent = try Fixture.noNewLine.load(as: String.self)
		let diffs = try [Diff](rawDiffContent: diffFileContent)

		XCTAssertEqual(diffs.count, 1)

		let diff = diffs.first
		XCTAssertEqual(diff?.removedFilePath, "a/.swiftlint.yml")
		XCTAssertEqual(diff?.addedFilePath, "b/.swiftlint.yml")

		XCTAssertEqual(diff?.hunks.count, 1)

		let hunk = diff?.hunks.first
		XCTAssertEqual(hunk?.oldLineStart, 11)
		XCTAssertEqual(hunk?.oldLineSpan, 6)
		XCTAssertEqual(hunk?.newLineStart, 11)
		XCTAssertEqual(hunk?.newLineSpan, 10)

		XCTAssertEqual(hunk?.lines.additions.count, 6)
		XCTAssertEqual(hunk?.lines.deletions.count, 2)
		XCTAssertEqual(hunk?.lines.unchanged.count, 4)
	}

	func testInit_newFileMode() throws {
		let diffFileContent = try Fixture.newFileMode.load(as: String.self)
		let diffs = try [Diff](rawDiffContent: diffFileContent)

		XCTAssertEqual(diffs.count, 1)

		let diff = diffs.first
		XCTAssertNil(diff?.removedFilePath)
		XCTAssertEqual(diff?.addedFilePath, "b/GitDiffSwift/Models/GitDiffLine.swift")

		XCTAssertEqual(diff?.hunks.count, 1)

		let hunk = diff?.hunks.first
		XCTAssertEqual(hunk?.oldLineStart, 0)
		XCTAssertEqual(hunk?.oldLineSpan, 0)
		XCTAssertEqual(hunk?.newLineStart, 1)
		XCTAssertEqual(hunk?.newLineSpan, 31)

		XCTAssertEqual(hunk?.lines.additions.count, 31)
		XCTAssertEqual(hunk?.lines.deletions.count, 0)
		XCTAssertEqual(hunk?.lines.unchanged.count, 0)
	}

	func testInit_renamedFileMode() throws {
		let diffFileContent = try Fixture.renamedFileMode.load(as: String.self)
		let diffs = try [Diff](rawDiffContent: diffFileContent)

		XCTAssertEqual(diffs.count, 1)

		let diff = diffs.first
		XCTAssertEqual(diff?.removedFilePath, "a/Sources/Layout/MessageCellLayoutContext.swift")
		XCTAssertEqual(diff?.addedFilePath, "b/Sources/Protocols/MediaItem.swift")

		XCTAssertEqual(diff?.hunks.count, 1)

		let hunk = diff?.hunks.first
		XCTAssertEqual(hunk?.oldLineStart, 24)
		XCTAssertEqual(hunk?.oldLineSpan, 25)
		XCTAssertEqual(hunk?.newLineStart, 24)
		XCTAssertEqual(hunk?.newLineSpan, 19)

		XCTAssertEqual(hunk?.lines.additions.count, 10)
		XCTAssertEqual(hunk?.lines.deletions.count, 16)
		XCTAssertEqual(hunk?.lines.unchanged.count, 9)
	}

	func testInit_deletedFileMode() throws {
		let diffFileContent = try Fixture.deletedFileMode.load(as: String.self)
		let diffs = try [Diff](rawDiffContent: diffFileContent)

		XCTAssertEqual(diffs.count, 1)

		let diff = diffs.first
		XCTAssertEqual(diff?.removedFilePath, "a/Sources/Layout/MessagesCollectionViewFlowLayout+Avatar.swift")
		XCTAssertNil(diff?.addedFilePath)

		XCTAssertEqual(diff?.hunks.count, 1)

		let hunk = diff?.hunks.first
		XCTAssertEqual(hunk?.oldLineStart, 1)
		XCTAssertEqual(hunk?.oldLineSpan, 85)
		XCTAssertEqual(hunk?.newLineStart, 0)
		XCTAssertEqual(hunk?.newLineSpan, 0)

		XCTAssertEqual(hunk?.lines.additions.count, 0)
		XCTAssertEqual(hunk?.lines.deletions.count, 85)
		XCTAssertEqual(hunk?.lines.unchanged.count, 0)
	}

	func testInit_multiFileChange() throws {
		let diffFileContent = try Fixture.multiFileChange.load(as: String.self)
		let diffs = try [Diff](rawDiffContent: diffFileContent)

		XCTAssertEqual(diffs.count, 3)

		// MARK: diffA

		let diffA = diffs.first
		XCTAssertEqual(diffA?.removedFilePath, "a/Cartfile.resolved")
		XCTAssertEqual(diffA?.addedFilePath, "b/Cartfile.resolved")

		XCTAssertEqual(diffA?.hunks.count, 1)

		let hunkA = diffA?.hunks.first
		XCTAssertEqual(hunkA?.oldLineStart, 1)
		XCTAssertEqual(hunkA?.oldLineSpan, 4)
		XCTAssertEqual(hunkA?.newLineStart, 1)
		XCTAssertEqual(hunkA?.newLineSpan, 4)

		XCTAssertEqual(hunkA?.lines.additions.count, 1)
		XCTAssertEqual(hunkA?.lines.deletions.count, 1)
		XCTAssertEqual(hunkA?.lines.unchanged.count, 3)

		// MARK: diffB

		let diffB = diffs.dropFirst().first
		XCTAssertNil(diffB?.removedFilePath)
		XCTAssertEqual(diffB?.addedFilePath, "b/Moya.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist")

		XCTAssertEqual(diffB?.hunks.count, 1)

		let hunkB = diffB?.hunks.first
		XCTAssertEqual(hunkB?.oldLineStart, 0)
		XCTAssertEqual(hunkB?.oldLineSpan, 0)
		XCTAssertEqual(hunkB?.newLineStart, 1)
		XCTAssertEqual(hunkB?.newLineSpan, 8)

		XCTAssertEqual(hunkB?.lines.additions.count, 8)
		XCTAssertEqual(hunkB?.lines.deletions.count, 0)
		XCTAssertEqual(hunkB?.lines.unchanged.count, 0)

		// MARK: diffC

		let diffC = diffs.dropFirst(2).first
		XCTAssertEqual(diffC?.removedFilePath, "a/Package.resolved")
		XCTAssertEqual(diffC?.addedFilePath, "b/Package.resolved")

		XCTAssertEqual(diffC?.hunks.count, 4)

		let hunkC = diffC?.hunks.first
		XCTAssertEqual(hunkC?.oldLineStart, 6)
		XCTAssertEqual(hunkC?.oldLineSpan, 8)
		XCTAssertEqual(hunkC?.newLineStart, 6)
		XCTAssertEqual(hunkC?.newLineSpan, 26)

		XCTAssertEqual(hunkC?.lines.additions.count, 20)
		XCTAssertEqual(hunkC?.lines.deletions.count, 2)
		XCTAssertEqual(hunkC?.lines.unchanged.count, 6)

		let hunkC2 = diffC?.hunks.dropFirst().first
		XCTAssertEqual(hunkC2?.oldLineStart, 15)
		XCTAssertEqual(hunkC2?.oldLineSpan, 8)
		XCTAssertEqual(hunkC2?.newLineStart, 33)
		XCTAssertEqual(hunkC2?.newLineSpan, 8)

		XCTAssertEqual(hunkC2?.lines.additions.count, 2)
		XCTAssertEqual(hunkC2?.lines.deletions.count, 2)
		XCTAssertEqual(hunkC2?.lines.unchanged.count, 6)

		let hunkC3 = diffC?.hunks.dropFirst(2).first
		XCTAssertEqual(hunkC3?.oldLineStart, 24)
		XCTAssertEqual(hunkC3?.oldLineSpan, 8)
		XCTAssertEqual(hunkC3?.newLineStart, 42)
		XCTAssertEqual(hunkC3?.newLineSpan, 8)

		XCTAssertEqual(hunkC3?.lines.additions.count, 2)
		XCTAssertEqual(hunkC3?.lines.deletions.count, 2)
		XCTAssertEqual(hunkC3?.lines.unchanged.count, 6)

		let hunkC4 = diffC?.hunks.dropFirst(3).first
		XCTAssertEqual(hunkC4?.oldLineStart, 33)
		XCTAssertEqual(hunkC4?.oldLineSpan, 8)
		XCTAssertEqual(hunkC4?.newLineStart, 51)
		XCTAssertEqual(hunkC4?.newLineSpan, 8)

		XCTAssertEqual(hunkC4?.lines.additions.count, 2)
		XCTAssertEqual(hunkC4?.lines.deletions.count, 2)
		XCTAssertEqual(hunkC4?.lines.unchanged.count, 6)
	}

	func testInit_hunkHeaderMissing() throws {
		let diffFileContent = try Fixture.hunkHeaderMissing.load(as: String.self)

		XCTAssertThrowsError(try Diff(rawDiffContent: diffFileContent)) { error in
			switch error {
			case Diff.Error.hunkHeaderMissing:
				break
			default:
				XCTFail("Diff initializer threw the wrong error")
			}
		}
	}

	func testInit_addedFileMissing() throws {
		let diffFileContent = try Fixture.addedFileMissing.load(as: String.self)

		XCTAssertThrowsError(try Diff(rawDiffContent: diffFileContent)) { error in
			switch error {
			case Diff.Error.filePathsNotFound:
				break
			default:
				XCTFail("Diff initializer threw the wrong error")
			}
		}
	}
}

extension DiffTests {
	func testInit_baseBranch_targetBranch() throws {
		Diff.interactor = DiffInteractorMock()

		let diff = try Diff(
			baseBranch: Branch(name: "master", source: .local),
			targetBranch: Branch(name: "develop", source: .local)
		)

		XCTAssertEqual(diff.hunks.count, 1)
	}

	func testInitArray_baseBranch_targetBranch() throws {
		Diff.interactor = DiffInteractorMock()
		
		let diffs = try [Diff](
			baseBranch: Branch(name: "release", source: .local),
			targetBranch: Branch(name: "develop", source: .local)
		)

		XCTAssertEqual(diffs.count, 3)
	}
}

extension Array where Element == Diff.Hunk.Line {
	var additions: [Diff.Hunk.Line] {
		return filter { $0.kind == .addition }
	}

	var deletions: [Diff.Hunk.Line] {
		return filter { $0.kind == .deletion }
	}

	var unchanged: [Diff.Hunk.Line] {
		return filter { $0.kind == .unchanged }
	}
}
