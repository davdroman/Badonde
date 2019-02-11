import Foundation

extension Optional where Wrapped: RangeReplaceableCollection {
	mutating func append(_ newElement: Wrapped.Element) {
		var collection = self ?? Wrapped()
		collection.append(newElement)
		self = collection
	}
}
