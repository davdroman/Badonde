import Foundation

extension Collection {
	public var nilIfEmpty: Self? {
		guard !isEmpty else {
			return nil
		}
		return self
	}

	public subscript (safe index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}

	public func compacted<Wrapped>() -> [Wrapped] where Element == Optional<Wrapped> {
		return compactMap { $0 }
	}
}
