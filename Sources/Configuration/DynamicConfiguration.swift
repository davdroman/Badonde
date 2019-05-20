import Foundation

public final class DynamicConfiguration: KeyValueInteractive {
	let configurations: [KeyValueInteractive]

	public init(prioritizedConfigurations: [KeyValueInteractive]) throws {
		self.configurations = prioritizedConfigurations
	}

	public func getValue<T>(ofType type: T.Type, forKeyPath keyPath: KeyPath) throws -> T? {
		return try configurations
			.lazy
			.compactMap { try $0.getValue(ofType: type, forKeyPath: keyPath) }
			.first
	}

	public func setValue<T>(_ value: T, forKeyPath keyPath: KeyPath) throws {
		try configurations.first?.setValue(value, forKeyPath: keyPath)
	}

	public func getRawValue(forKeyPath keyPath: KeyPath) throws -> String? {
		return try configurations
			.lazy
			.compactMap { try $0.getRawValue(forKeyPath: keyPath) }
			.first
	}

	public func setRawValue(_ value: String, forKeyPath keyPath: KeyPath) throws {
		try configurations.first?.setRawValue(value, forKeyPath: keyPath)
	}

	public func removeValue(forKeyPath keyPath: KeyPath) throws {
		try configurations.first?.removeValue(forKeyPath: keyPath)
	}
}
