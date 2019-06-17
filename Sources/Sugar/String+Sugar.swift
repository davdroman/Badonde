import Foundation
import CommonCrypto
import SwiftyStringScore

extension String {
	public init(staticString: StaticString) {
		self = staticString.withUTF8Buffer {
			String(decoding: $0, as: UTF8.self)
		}
	}
}

extension String {
	public func components(losslesslySeparatedBy separator: CharacterSet) -> [String] {
		var components = [String]()
		var latestSeparatorIndex = startIndex

		for index in indices {
			let character = self[index]
			let scalarValue = character.unicodeScalars.map { $0.value }.reduce(0, +)
			guard
				let scalar = Unicode.Scalar(scalarValue),
				separator.contains(scalar)
			else {
				continue
			}

			if index > latestSeparatorIndex {
				let component = String(self[latestSeparatorIndex..<index])
				components.append(component)
			}

			latestSeparatorIndex = index
		}

		if latestSeparatorIndex < endIndex {
			let component = String(self[latestSeparatorIndex..<endIndex])
			components.append(component)
		}

		return components
	}
}

extension String {
	public func firstMatch(forRegex regex: String, options: String.CompareOptions = []) -> String? {
		var options = options
		options.insert(.regularExpression)
		guard let matchRange = range(of: regex, options: options, range: nil, locale: nil) else {
			return nil
		}
		return String(self[matchRange])
	}

	public func matchesRegex(_ regex: String, options: String.CompareOptions = []) -> Bool {
		return firstMatch(forRegex: regex, options: options) != nil
	}
}

extension String {
	public static func ~= (lhs: String, rhs: String) -> Bool {
		return lhs.isRoughly(rhs)
	}

	public func isRoughly(_ otherString: String) -> Bool {
		return otherString.score(word: self, fuzziness: 1) > 0.5
	}
}

extension String {
	public func base64() -> String {
		return Data(self.utf8).base64EncodedString()
	}
}

extension String {
	public func sha1() -> String {
		let data = Data(self.utf8)
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
		data.withUnsafeBytes {
			_ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
		}
		let hexBytes = digest.map { String(format: "%02hhx", $0) }
		return hexBytes.joined()
	}
}
