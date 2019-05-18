import Foundation
import SwiftCLI
import Configuration
import Git
import Sugar

class ConfigCommand: Command {
	let name = "config"
	let shortDescription = "Get and set project or global options"
	lazy var longDescription: String = {
		let formattedKeyPaths = Configuration.supportedKeyPaths
			.map { "  " + [$0.rawValue, $0.description].compactMap({ $0 }).joined(separator: " - ") }
			.joined(separator: "\n")
		return """
		Get and set project or global options.

		Keys:

		\(formattedKeyPaths)
		"""
	}()

	let global = Flag(
		"--global",
		description: """
		For writing options: write to global ~/.config/badonde/config.json file
		rather than the repository .badonde/config.json.

		For reading options: read only from global ~/.config/badonde/config.json
		rather than from all available files.

		"""
	)

	let local = Flag(
		"--local",
		description: """
		For writing options: write to the repository .badonde/config.json file.
		This is the default behavior.

		For reading options: read only from the repository .badonde/config.json
		rather than from all available files.

		"""
	)

	let get = Flag("--get", description: "Get the value for a given key.\n")
	let set = Flag("--set", description: "Set the value for a given key.\n")
	let unset = Flag("--unset", description: "Remove the value matching the key from config file.\n")

	var optionGroups: [OptionGroup] {
		return [
			.atMostOne(global, local),
			.atMostOne(get, set, unset),
		]
	}

	let key = Parameter(completion: .none)
	let value = OptionalParameter(completion: .none)

	func execute() throws {
		guard let keyPath = KeyPath(rawValue: key.value) else {
			throw Error.incompatibleKey(key.value)
		}

		let keyPathIsSupported = Configuration.supportedKeyPaths.contains(keyPath)
		let configuration = try self.configuration(forLocalValue: local.value, globalValue: global.value)

		switch (get.value, set.value, unset.value) {
		case (true, false, false): // get
			if let rawValue = try configuration.getRawValue(forKeyPath: keyPath) {
				stdout <<< rawValue
			}
		case (false, true, false): // set
			Logger.step("Setting...")
			guard let value = value.value else {
				throw Error.valueMissing(forKey: key.value)
			}
			try configuration.setRawValue(value, forKeyPath: keyPath)
			if !keyPathIsSupported {
				Logger.info("Value '\(value)' was set for '\(keyPath.rawValue)', however this key is not used by Badonde")
			}
		case (false, false, true): // unset
			Logger.step("Unsetting...")
			try configuration.removeValue(forKeyPath: keyPath)
		case (false, false, false): // none (dynamic)
			if let value = value.value {
				Logger.step("Setting...")
				try configuration.setRawValue(value, forKeyPath: keyPath)
				if !keyPathIsSupported {
					Logger.info("Value '\(value)' was set for '\(keyPath.rawValue)', however this key is not used by Badonde")
				}
			} else if let value = try configuration.getRawValue(forKeyPath: keyPath) {
				stdout <<< value
			}
		default:
			fatalError("More than one config action option was specified")
		}
	}

	private func configuration(forLocalValue localValue: Bool, globalValue: Bool) throws -> KeyValueInteractive {
		switch (localValue, globalValue) {
		case (true, false):
			let repository = try Repository()
			return try Configuration(scope: .local(repository.topLevelPath))
		case (false, true):
			return try Configuration(scope: .global)
		case (false, false):
			let localScope = (try? Repository().topLevelPath).map { Configuration.Scope.local($0) }
			return try DynamicConfiguration(prioritizedScopes: [localScope, .global].compacted())
		case (true, true):
			fatalError("More than one config scope option was specified")
		}
	}
}
