import SwiftyStringScore

extension Array where Element == String {
	func fuzzyMatch(word: String) -> String? {
		return map { (score: $0.score(word: word, fuzziness: 1), string: $0) }
			.filter { $0.score > 0.5 }
			.sorted { $0.score > $1.score }
			.first?
			.string
	}
}
