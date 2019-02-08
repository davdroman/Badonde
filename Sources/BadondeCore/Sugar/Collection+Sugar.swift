import Foundation

extension Collection {
	var nilIfEmpty: Self? {
		guard !isEmpty else {
			return nil
		}
		return self
	}

	subscript (safe index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
}
