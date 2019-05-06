import Foundation

public final class Configuration {
	let url: URL
	let fileInteractor: JSONFileInteractor
	var rawObject: [String: Any]
	var keyPathedObject: [String: Any] {
		get {
			return rawObject.flatten()
		}
		set {
			rawObject = newValue.unflatten()
		}
	}

	public let supportedKeyPaths: [KeyPath]

	public convenience init(contentsOf url: URL, supportedKeyPaths: [KeyPath]) throws {
		try self.init(contentsOf: url, supportedKeyPaths: supportedKeyPaths, fileInteractor: FileInteractor())
	}

	init(contentsOf url: URL, supportedKeyPaths: [KeyPath], fileInteractor: JSONFileInteractor) throws {
		self.url = url
		self.fileInteractor = fileInteractor
		self.rawObject = try fileInteractor.read(from: url)
		self.supportedKeyPaths = supportedKeyPaths
	}

	public func getValue<T>(ofType type: T.Type, forKeyPath keyPath: KeyPath) throws -> T? {
		guard let rawValue = getRawValue(forKeyPath: keyPath) else {
			return nil
		}

		switch type {
		case is Bool.Type:
			guard let boolValue = Bool(rawValue) else {
				throw Error.typeBridgingFailed(rawValue, type)
			}
			return boolValue as? T
		case is Double.Type:
			guard let doubleValue = Double(rawValue) else {
				throw Error.typeBridgingFailed(rawValue, type)
			}
			return doubleValue as? T
		case is Int.Type:
			guard let intValue = Int(rawValue) else {
				throw Error.typeBridgingFailed(rawValue, type)
			}
			return intValue as? T
		case is String.Type:
			return rawValue as? T
		default:
			throw Error.invalidBridgingType(type)
		}
	}

	public func setValue<T>(_ value: T, forKeyPath keyPath: KeyPath) throws {
		switch T.self {
		case is Bool.Type, is Double.Type, is Int.Type, is String.Type:
			break
		default:
			throw Error.invalidValueType(T.self)
		}

		let existingKeyPaths = keyPathedObject.keys.compactMap { KeyPath(rawValue: $0) }
		let allocatedKeyPaths = existingKeyPaths + supportedKeyPaths
		let isKeyPathCompatible = keyPath.isCompatible(in: allocatedKeyPaths)

		guard isKeyPathCompatible else {
			throw Error.incompatibleKeyPath(keyPath)
		}

		keyPathedObject[keyPath.rawValue] = value

		try fileInteractor.write(rawObject, to: url)
	}

	public func getRawValue(forKeyPath keyPath: KeyPath) -> String? {
		guard let value = keyPathedObject[keyPath.rawValue] else {
			return nil
		}

		switch value {
		case is [Any], is NSNull:
			return nil
		case let boolValue as Bool:
			return boolValue ? "true" : "false"
		default:
			return String(describing: value)
		}
	}

	public func setRawValue(_ value: String, forKeyPath keyPath: KeyPath) throws {
		if let boolValue = Bool(value) {
			try setValue(boolValue, forKeyPath: keyPath)
		} else if let doubleValue = Double(value) {
			if doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
				try setValue(Int(doubleValue), forKeyPath: keyPath)
			} else {
				try setValue(doubleValue, forKeyPath: keyPath)
			}
		} else {
			try setValue(value, forKeyPath: keyPath)
		}
	}
}
