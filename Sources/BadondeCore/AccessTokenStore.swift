import Foundation

final class AccessTokenStore {

	static let badondePath = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent(".badonde", isDirectory: true)
	static let configPath = AccessTokenStore.badondePath.appendingPathComponent("config.json")

	var config: AccessTokenConfig? {
		didSet {
			guard let config = config else {
				do {
					try FileManager.default.removeItem(at: AccessTokenStore.configPath)
				} catch {
					print(error)
				}
				return
			}

			if !FileManager.default.fileExists(atPath: AccessTokenStore.badondePath.absoluteString) {
				do {
					try FileManager.default.createDirectory(at: AccessTokenStore.badondePath, withIntermediateDirectories: true, attributes: nil)
				} catch {
					print(error)
				}
			}

			do {
				let configData = try JSONEncoder().encode(config)
				try configData.write(to: AccessTokenStore.configPath)
			} catch {
				print(error)
			}
		}
	}

	init() {
		do {
			let configData = try Data(contentsOf: AccessTokenStore.configPath, options: [])
			self.config = try JSONDecoder().decode(AccessTokenConfig.self, from: configData)
		} catch {
			self.config = nil
		}
	}
}

struct AccessTokenConfig: Codable {
	var jiraEmail: String
	var jiraApiToken: String
	var githubAccessToken: String
}
