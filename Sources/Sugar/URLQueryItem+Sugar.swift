import Foundation

extension URLQueryItem {
	public init?(name: String, mandatoryValue: String?) {
		guard let value = mandatoryValue else {
			return nil
		}
		self.init(name: name, value: value)
	}
}
