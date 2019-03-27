import Foundation
import SwiftCLI
import GitHub

class AppifyCommand: Command {
	let name = "appify"
	let shortDescription = "Generates an .app for your specific project"

	enum Error: ProcessError {
		case noAppTemplateAvailable

		var message: String? {
			switch self {
			case .noAppTemplateAvailable:
				return "No .app templates available on GitHub, please contact d@vidroman.dev"
			}
		}
	}

	func execute() throws {
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown throughout the codepath

		Logger.step("Checking for existing configuration")
		let configurationStore = ConfigurationStore()
		let configuration = try BurghCommand().getOrPromptConfiguration(for: configurationStore) // FIXME: refactor me

		Logger.step("Searching for latest .app template available")
		let releaseAPI = Release.API(accessToken: configuration.githubAccessToken)
		let possibleLatestReleaseAsset = try releaseAPI.getReleases(for: "davdroman/Badonde")
			.lazy
			.sorted(by: { $0.date > $1.date })
			.first(where: { !$0.assets.isEmpty })?
			.assets
			.first

		guard let latestReleaseAsset = possibleLatestReleaseAsset else {
			throw Error.noAppTemplateAvailable
		}

		let folderPath = "/tmp/Badonde-AppTemplate"
		let zipPath = folderPath + ".zip"
		let appName = "Badonde.app"
		let tmpAppPath = "\(folderPath)/\(appName)"
		let workflowFilePath = URL(fileURLWithPath: "\(tmpAppPath)/Contents/document.wflow")

		Logger.step("Downloading .app template")
		try run(bash: "curl -s -L -o \(zipPath) -O \(latestReleaseAsset.downloadUrl)")
		try run(bash: "unzip -qq -o \(zipPath) -d \(folderPath)")

		Logger.step("Setting up Badonde.app for your current project folder")
		let currentDirectory = try capture(bash: "pwd").stdout
		var workflowFileContents = try String(data: Data(contentsOf: workflowFilePath), encoding: .utf8)
		workflowFileContents = workflowFileContents?.replacingOccurrences(of: "{PATH_TO_PROJECT_DIR}", with: "<string>\(currentDirectory)</string>")
		try workflowFileContents?.write(to: workflowFilePath, atomically: true, encoding: .utf8)

		Logger.step("Installing Badonde.app")
		let appPath = "/Applications/\(appName)"
		try run(bash: "cp -rf \(tmpAppPath) \(appPath)")

		Logger.finish()
	}
}
