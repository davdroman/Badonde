import Foundation

public protocol KeyValueInteractive {
	func getValue<T>(ofType type: T.Type, forKeyPath keyPath: KeyPath) throws -> T?
	func setValue<T: Equatable>(_ value: T, forKeyPath keyPath: KeyPath) throws
	func getRawValue(forKeyPath keyPath: KeyPath) throws -> String?
	func setRawValue(_ value: String, forKeyPath keyPath: KeyPath) throws
	func removeValue(forKeyPath keyPath: KeyPath) throws
}

public class Configuration: KeyValueInteractive {
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
	var allocatedKeyPaths: [KeyPath] {
		let existingKeyPaths = keyPathedObject.keys.compactMap { KeyPath(rawValue: $0) }
		return existingKeyPaths + supportedKeyPaths
	}

	public let path: String
	public let supportedKeyPaths: [KeyPath]

	public convenience init(contentsOfFile path: String, supportedKeyPaths: [KeyPath]) throws {
		try self.init(contentsOfFile: path, supportedKeyPaths: supportedKeyPaths, fileInteractor: FileInteractor())
	}

	init(contentsOfFile path: String, supportedKeyPaths: [KeyPath], fileInteractor: JSONFileInteractor) throws {
		self.path = path
		self.fileInteractor = fileInteractor
		self.rawObject = try fileInteractor.read(from: path)
		self.supportedKeyPaths = supportedKeyPaths
	}

	public func getValue<T>(ofType type: T.Type, forKeyPath keyPath: KeyPath) throws -> T? {
		guard let rawValue = try getRawValue(forKeyPath: keyPath) else {
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

	public func setValue<T: Equatable>(_ value: T, forKeyPath keyPath: KeyPath) throws {
		switch T.self {
		case is Bool.Type, is Double.Type, is Int.Type, is String.Type:
			break
		default:
			throw Error.invalidValueType(T.self)
		}

		guard keyPath.isCompatible(in: allocatedKeyPaths) else {
			throw Error.incompatibleKeyPath(keyPath)
		}

		// Optimization to not write to disk unnecessarily if the new value isn't.
		if let existingValue = keyPathedObject[keyPath.rawValue] as? T, existingValue == value {
			return
		}

		keyPathedObject[keyPath.rawValue] = value

		try fileInteractor.write(rawObject, to: path)
	}

	public func getRawValue(forKeyPath keyPath: KeyPath) throws -> String? {
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

	public func removeValue(forKeyPath keyPath: KeyPath) throws {
		guard keyPath.isCompatible(in: allocatedKeyPaths) else {
			throw Error.incompatibleKeyPath(keyPath)
		}

		keyPathedObject[keyPath.rawValue] = nil

		try fileInteractor.write(rawObject, to: path)
	}
}

extension Configuration {
	public enum Error {
		case typeBridgingFailed(String, Any.Type)
		case invalidBridgingType(Any.Type)
		case invalidValueType(Any.Type)
		case incompatibleKeyPath(KeyPath)
	}
}

extension Configuration.Error: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case let .typeBridgingFailed(value, type):
			return "Value '\(value)' could not be bridged to type '\(type)'"
		case let .invalidBridgingType(type):
			return "'\(type)' cannot be used as bridging type"
		case let .invalidValueType(type):
			return "'\(type)' cannot be used as value type"
		case let .incompatibleKeyPath(keyPath):
			return "'\(keyPath.rawValue)' could not be used as a key"
		}
	}
}
