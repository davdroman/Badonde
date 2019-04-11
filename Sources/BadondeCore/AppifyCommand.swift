import Foundation
import SwiftCLI
import GitHub
import OSAKit

class AppifyCommand: Command {
	let name = "appify"
	let shortDescription = "Generates a Badonde.app for your specific project"

	func execute() throws {
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown along the way

		Logger.step("Checking for existing configuration")
		let configurationStore = ConfigurationStore()
		let configuration = try BurghCommand().getOrPromptConfiguration(for: configurationStore) // FIXME: refactor me

		Logger.step("Searching for latest .app template available")
		let releaseAPI = Release.API(accessToken: configuration.githubAccessToken)
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
		try run(bash: "curl -s -L -o \(zipPath) -O \(latestReleaseAsset.downloadUrl)")
		try run(bash: "unzip -qq -o \(zipPath) -d \(folderPath)")

		Logger.step("Setting up Badonde.app for your current project folder")
		let currentDirectory = try capture(bash: "pwd").stdout
		let applescript = try OSAScript(contentsOf: applescriptFilePath, languageInstance: nil, using: OSAStorageOptions.compileIntoContext)
		let newApplescriptSource = applescript.source.replacingOccurrences(of: "{PATH_TO_PROJECT_DIR}", with: currentDirectory)
		let newApplescript = OSAScript(source: newApplescriptSource)
		guard let newApplescriptCompiledSource = newApplescript.compiledData(forType: "scpt", using: OSAStorageOptions.stayOpenApplet, error: nil) else {
			throw Error.appCompilationFailed
		}
		try newApplescriptCompiledSource.write(to: applescriptFilePath, options: .atomic)

		Logger.step("Installing Badonde.app")
		let appPath = "/Applications/\(appName)"
		try run(bash: "rm -rf \(appPath)")
		try run(bash: "cp -rf \(tmpAppPath) \(appPath)")

		Logger.step("Adding app to Script Menu")
		try run(bash: "ln -nsf \(appPath) ~/Library/Scripts/\(appName)")
		try run(bash: "open '/System/Library/CoreServices/Script Menu.app'")

		Logger.step("Installing service")
		let serviceName = "Run Badonde"
		let serviceFilename = "Run\\ Badonde.workflow"
		let servicePath = "~/Library/Services/\(serviceFilename)"
		try run(bash: "rm -rf \(servicePath)")
		let tmpServicePath = "\(folderPath)/\(serviceFilename)"
		try run(bash: "cp -rf \(tmpServicePath) \(servicePath)")
		try run(bash: "/System/Library/CoreServices/pbs -flush")

		Logger.step("Setting up shortcut ⌃⌥⌘B")
		let service = Service(bundleIdentifier: nil, menuItemName: serviceName, message: "runWorkflowAsService")
		try Service.KeyEquivalentConfigurator().addKeyEquivalent("@~^b", for: service)
		try run(bash: "defaults read pbs > /dev/null")

		Logger.step("Cleaning up")
		try run(bash: "rm -rf \(zipPath)")
		try run(bash: "rm -rf \(folderPath)")

		try run(bash: "open -R \(appPath)")

		Logger.finish()
	}
}
