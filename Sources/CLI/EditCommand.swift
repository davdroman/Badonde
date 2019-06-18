import Foundation
import SwiftCLI
import Core
import Git

final class EditCommand: Command {
	let name = "edit"
	let shortDescription = "Opens Badondefile.swift on Xcode"
	let longDescription =
		"""
		Opens Badondefile.swift on Xcode.

		This command helps editing your current Badondefile.swift
		by setting up an temporary Xcode project for it enabling
		full autocompletion support.
		"""

	let startDatePointer: UnsafeMutablePointer<Date>

	init(startDatePointer: UnsafeMutablePointer<Date>) {
		self.startDatePointer = startDatePointer
	}

	func execute() throws {
		let repositoryPath = try Repository(atPath: FileManager.default.currentDirectoryPath).topLevelPath
		try Badondefile.EditingCoordinator().editBadondefile(forRepositoryPath: repositoryPath)

		// Reset start date because editing take an indefinite amount of time
		// and this time is irrelevant to tool performance.
		startDatePointer.pointee = Date()
	}
}
