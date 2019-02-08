import Foundation

extension URLQueryItem {
	init?(name: String, mandatoryValue: String?) {
		guard let value = mandatoryValue else {
			return nil
		}
		self.init(name: name, value: value)
	}
}
