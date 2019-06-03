import Foundation

extension DispatchGroup {
	public func asyncExecuteAndWait(_ blocks: (() -> Void)...) {
		for block in blocks {
			DispatchQueue(label: "dev.davidroman.DispatchGroup").async(group: self, execute: DispatchWorkItem(block: block))
		}
		wait()
	}
}
