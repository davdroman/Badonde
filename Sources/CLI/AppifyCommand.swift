import Foundation
import SwiftCLI
import Configuration
import Core
import Git
import GitHub
import OSAKit

final class AppifyCommand: Command {
	let name = "appify"
	let shortDescription = "Generates a Badonde.app for your project"

	func execute() throws {
		Logger.step("Reading configuration")
		let projectPath = try Repository(atPath: FileManager.default.currentDirectoryPath).topLevelPath

		guard
			let configuration = try? DynamicConfiguration(prioritizedScopes: [.local(path: projectPath), .global]),
			let githubAccessToken = try configuration.getRawValue(forKeyPath: .githubAccessToken)
		else {
			throw Error.configMissing
		}

		Logger.step("Searching for latest .app template available")
		let releaseAPI = Release.API(accessToken: githubAccessToken)
		let currentVersion = CommandLineTool.Constant.version
		let possibleLatestReleaseAsset = try releaseAPI.getReleases(for: "davdroman/Badonde")
			.lazy
			.filter { $0.version.compare(currentVersion, options: .numeric) != .orderedDescending }
			.sorted { $0.date > $1.date }
			.first { !$0.assets.isEmpty }?
			.assets
			.first

		guard let latestReleaseAsset = possibleLatestReleaseAsset else {
			throw Error.noAppTemplateAvailable
		}

		let folderPath = "/tmp/Badonde-AppTemplate"
		let zipPath = folderPath + ".zip"
		let appName = "Badonde.app"
		let tmpAppPath = "\(folderPath)/\(appName)"
		let applescriptFilePath = URL(fileURLWithPath: "\(tmpAppPath)/Contents/Resources/Scripts/main.scpt")

		Logger.step("Downloading .app template")
		_ = try Task.capture(bash: "rm -rf \(zipPath)")
		_ = try Task.capture(bash: "curl -s -L -o \(zipPath) -O \(latestReleaseAsset.downloadUrl)")
		_ = try Task.capture(bash: "rm -rf \(folderPath)")
		_ = try Task.capture(bash: "unzip -qq -o \(zipPath) -d \(folderPath)")

		Logger.step("Setting up Badonde.app for your current project folder")
		let currentDirectory = try Task.capture(bash: "pwd").stdout
		let applescript = try OSAScript(contentsOf: applescriptFilePath, languageInstance: nil, using: OSAStorageOptions.compileIntoContext)
		let newApplescriptSource = applescript.source.replacingOccurrences(of: "{PATH_TO_PROJECT_DIR}", with: currentDirectory)
		let newApplescript = OSAScript(source: newApplescriptSource)
		guard let newApplescriptCompiledSource = newApplescript.compiledData(forType: "scpt", using: OSAStorageOptions.stayOpenApplet, error: nil) else {
			throw Error.appCompilationFailed
		}
		try newApplescriptCompiledSource.write(to: applescriptFilePath, options: .atomic)

		Logger.step("Installing Badonde.app")
		let appPath = "/Applications/\(appName)"
		_ = try Task.capture(bash: "rm -rf \(appPath)")
		_ = try Task.capture(bash: "cp -rf \(tmpAppPath) \(appPath)")

		Logger.step("Adding app to Script Menu")
		_ = try Task.capture(bash: "mkdir -p ~/Library/Scripts")
		_ = try Task.capture(bash: "mkdir -p ~/Library/Services")
		_ = try Task.capture(bash: "ln -nsf \(appPath) ~/Library/Scripts/\(appName)")
		do {
			_ = try Task.capture(bash: "open '/System/Library/CoreServices/Script Menu.app'")
		} catch {
			Logger.info("App was added to the Script Menu, to show go to Script Editor.app -> Preferences -> Show Script menu in menu bar")
		}

		Logger.step("Installing service")
		let serviceName = "Run Badonde"
		let serviceFilename = "Run\\ Badonde.workflow"
		let servicePath = "~/Library/Services/\(serviceFilename)"
		_ = try Task.capture(bash: "rm -rf \(servicePath)")
		let tmpServicePath = "\(folderPath)/\(serviceFilename)"
		_ = try Task.capture(bash: "cp -rf \(tmpServicePath) \(servicePath)")
		_ = try Task.capture(bash: "/System/Library/CoreServices/pbs -flush")

		Logger.step("Setting up shortcut CMD+ALT+CTRL+B")
		let service = Service(bundleIdentifier: nil, menuItemName: serviceName, message: "runWorkflowAsService")
		try Service.KeyEquivalentConfigurator().addKeyEquivalent("@~^b", for: service)
		_ = try Task.capture(bash: "defaults read pbs")
		Logger.info("Shortcut was set up but you might need to close currently active applications for it to work")

		_ = try Task.capture(bash: "open -R \(appPath)")
	}
}

extension AppifyCommand {
	enum Error {
		case configMissing
		case noAppTemplateAvailable
		case appCompilationFailed
	}
}

extension AppifyCommand.Error: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .configMissing:
			return "Configuration not found, please set up Badonde by running 'badonde init'"
		case .noAppTemplateAvailable:
			return "No .app templates available on GitHub, please contact d@vidroman.dev"
		case .appCompilationFailed:
			return "AppleScript app compilation failed"
		}
	}
}
