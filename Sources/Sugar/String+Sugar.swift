import Foundation
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
	public func isRoughly(_ otherString: String) -> Bool {
		return otherString.score(word: self, fuzziness: 1) > 0.5
	}

	public static func ~= (lhs: String, rhs: String) -> Bool {
		return lhs.isRoughly(rhs)
	}
}

extension String {
	public func base64(using encoding: String.Encoding = .utf8) -> String? {
		guard let stringData = data(using: encoding) else {
			return nil
		}
		return stringData.base64EncodedString()
	}
}
