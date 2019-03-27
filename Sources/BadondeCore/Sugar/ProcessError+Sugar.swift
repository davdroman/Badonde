import SwiftCLI

extension ProcessError where Self: Swift.Error {
	var message: String? {
		return localizedDescription
	}
}

extension ProcessError {
	var exitStatus: Int32 {
		return 1
	}
}
