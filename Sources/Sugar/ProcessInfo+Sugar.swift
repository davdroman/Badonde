import Foundation

extension ProcessInfo {
	public static var isDebugging: Bool {
		#if DEBUG
		return true
		#else
		return false
		#endif
	}

	public static var isUnitTesting: Bool {
		return processInfo.environment["XCTestConfigurationFilePath"] != nil
	}
}
