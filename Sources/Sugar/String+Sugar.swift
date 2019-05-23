import Foundation

extension String {
    public init(staticString: StaticString) {
        self = staticString.withUTF8Buffer {
            String(decoding: $0, as: UTF8.self)
        }
    }

	public func matchesRegex(_ regex: String) -> Bool {
		return range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
	}
}
