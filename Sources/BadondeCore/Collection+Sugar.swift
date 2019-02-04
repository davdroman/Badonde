import Foundation

extension Collection {
	var nilIfEmpty: Self? {
		guard !isEmpty else {
			return nil
		}
		return self
	}
}
