import Foundation
import SwiftCLI
import Configuration

class ConfigCommand: Command {
	let name = "config"
	let shortDescription = "Get and set project or global options"

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
		defer { Logger.fail() } // defers failure call if `Logger.finish()` isn't called at the end, which means an error was thrown along the way

		// TODO: migrate old config if needed

		guard let keyPath = KeyPath(rawValue: key.value) else {
			throw Error.incompatibleKey(key.value)
		}

		let configuration = try self.configuration(forLocalValue: local.value, globalValue: global.value)

		switch (get.value, set.value, unset.value) {
		case (true, false, false): // get
			if let rawValue = try configuration.getRawValue(forKeyPath: keyPath) {
				stdout <<< rawValue
			}
		case (false, true, false): // set
			guard let value = value.value else {
				throw Error.valueMissing(forKey: key.value)
			}
			try configuration.setRawValue(value, forKeyPath: keyPath)
		case (false, false, true): // unset
			try configuration.removeValue(forKeyPath: keyPath)
		case (false, false, false): // none (dynamic)
			if let value = value.value {
				try configuration.setRawValue(value, forKeyPath: keyPath)
			} else if let value = try configuration.getRawValue(forKeyPath: keyPath) {
				stdout <<< value
			}
		default:
			fatalError("More than one config action option was specified")
		}

		Logger.finish()
	}

	private func configuration(forLocalValue localValue: Bool, globalValue: Bool) throws -> KeyValueInteractive {
		switch (localValue, globalValue) {
		case (true, false):
			return try Configuration(scope: .local)
		case (false, true):
			return try Configuration(scope: .global)
		case (false, false):
			return try DynamicConfiguration(prioritizedScopes: [.local, .global])
		case (true, true):
			fatalError("More than one config scope option was specified")
		}
	}
}
