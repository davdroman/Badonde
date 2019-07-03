import Foundation
import SwiftCLI
import Core
import Sugar

extension Badondefile {
	final class EditingCoordinator {
		init() { }

		func editBadondefile(forRepositoryPath path: String) throws {
			let badondefilePath = try Badondefile.path(forRepositoryPath: path)
			let fileManager = FileManager.default

			Logger.step("Generating Xcode project for Badondefile")

			let badondefileProjectURL = fileManager.temporaryDirectory.appendingPathComponent("Badondefile-\(path.sha1())")
			if !fileManager.fileExists(atPath: badondefileProjectURL.path) {
				try fileManager.createDirectory(atPath: badondefileProjectURL.path, withIntermediateDirectories: false, attributes: nil)
			}

			let packageFilePath = badondefileProjectURL.appendingPathComponent("Package.swift").path
			let packageFileContents = """
			// swift-tools-version:5.0
			// The swift-tools-version declares the minimum version of Swift required to build this package.

			import PackageDescription

			let package = Package(
				name: "Badondefile",
				platforms: [.macOS(.v10_13)],
				products: [.library(name: "BadondefileProduct", targets: ["Badondefile"])],
				dependencies: [],
				targets: [.target(name: "Badondefile", dependencies: [])]
			)
			"""
			try fileManager.createFile(atPath: packageFilePath, withIntermediateDirectories: false, contents: Data(packageFileContents.utf8))

			let sourceURL = badondefileProjectURL.appendingPathComponent("Sources/Badondefile")
			let mainFilePath = sourceURL.appendingPathComponent("main.swift").path
			if !fileManager.fileExists(atPath: sourceURL.path) {
				try fileManager.createDirectory(at: sourceURL, withIntermediateDirectories: true, attributes: nil)
			}
			try Data(contentsOf: URL(fileURLWithPath: badondefilePath)).write(to: URL(fileURLWithPath: mainFilePath))

			let xcconfigPath = badondefileProjectURL.appendingPathComponent("config.xcconfig").path
			let librariesPath = Badondefile.librariesPath(forRepositoryPath: path)
			let xcconfigContents = """
			LIBRARY_SEARCH_PATHS = \(librariesPath)
			OTHER_SWIFT_FLAGS = -DXcode -I \(librariesPath) -L \(librariesPath)
			OTHER_LDFLAGS = -l BadondeKit
			"""
			try fileManager.createFile(atPath: xcconfigPath, withIntermediateDirectories: false, contents: Data(xcconfigContents.utf8))

			_ = try Task.capture(bash: "(cd \(badondefileProjectURL.path) && swift package generate-xcodeproj --xcconfig-overrides config.xcconfig)")

			let xcodeProjectPath = badondefileProjectURL.appendingPathComponent("Badondefile.xcodeproj").path
			_ = try Task.capture(bash: "open '\(xcodeProjectPath)'")

			Logger.info("Badonde will keep running, in order to save any changes you make in Xcode back to the original Badondefile")
			Logger.info("Press the RETURN key once you're done editing")
			_ = readLine() // waits for ENTER keystroke to save file back

			Logger.step("Saving Badondefile.swift")
			try Data(contentsOf: URL(fileURLWithPath: mainFilePath)).write(to: URL(fileURLWithPath: badondefilePath))
		}
	}
}
