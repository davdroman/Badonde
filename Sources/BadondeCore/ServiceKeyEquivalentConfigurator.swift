import Foundation

struct Service {
	var bundleIdentifier: String?
	var menuItemName: String
	var message: String

	var key: String {
		return [bundleIdentifier ?? "(null)", menuItemName, message].joined(separator: " - ")
	}
}

extension Service {
	final class KeyEquivalentConfigurator {
		enum Constant {
			static let pbsPlistPath = FileManager().homeDirectoryForCurrentUser.appendingPathComponent("Library/Preferences/pbs.plist")
			static let serviceStatusKey = "NSServicesStatus"
			static let keyEquivalentKey = "key_equivalent"
		}

		private var configuration: [String: Any]

		init() throws {
			let configuration = try? PropertyListSerialization.propertyList(
				from: Data(contentsOf: Constant.pbsPlistPath),
				options: .mutableContainersAndLeaves,
				format: nil
			)

			self.configuration = configuration as? [String: Any] ?? [String: Any]()
		}

		func addKeyEquivalent(_ keyEquivalent: String, for service: Service) throws {
			var services = configuration[Constant.serviceStatusKey] as? [String: Any] ?? [String: Any]()

			let serviceHasKeyEquivalent = services[service.key] != nil
			guard !serviceHasKeyEquivalent else {
				return
			}

			services[service.key] = [Constant.keyEquivalentKey: keyEquivalent]
			configuration[Constant.serviceStatusKey] = services

			try configurationData().write(to: Constant.pbsPlistPath)
		}

		private func configurationData() throws -> Data {
			return try PropertyListSerialization.data(fromPropertyList: configuration, format: .xml, options: 0)
		}
	}
}
