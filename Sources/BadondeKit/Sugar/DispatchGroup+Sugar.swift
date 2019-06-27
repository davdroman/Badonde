import Foundation
import Sugar

// Hopefully eventually replaceable with a native async/await mechanism.
// https://gist.github.com/lattner/429b9070918248274f25b714dcfc7619
extension DispatchGroup {
	private func asyncExecuteAndWait(_ blocks: (() -> Void)...) {
		for block in blocks {
			DispatchQueue(label: "dev.davidroman.DispatchGroup").async(group: self, execute: DispatchWorkItem(block: block))
		}
		wait()
	}

	@discardableResult
	public func asyncExecuteAndWait<A, B, C, D, E, F, G, H, I, J>(
		_ blockA: @escaping () throws -> A,
		_ blockB: @escaping () throws -> B,
		_ blockC: @escaping () throws -> C,
		_ blockD: @escaping () throws -> D,
		_ blockE: @escaping () throws -> E,
		_ blockF: @escaping () throws -> F,
		_ blockG: @escaping () throws -> G,
		_ blockH: @escaping () throws -> H,
		_ blockI: @escaping () throws -> I,
		_ blockJ: @escaping () throws -> J
	) -> (A, B, C, D, E, F, G, H, I, J) {
		var a: A!, b: B!, c: C!, d: D!, e: E!, f: F!, g: G!, h: H!, i: I!, j: J!
		asyncExecuteAndWait(
			{ a = trySafely(blockA) },
			{ b = trySafely(blockB) },
			{ c = trySafely(blockC) },
			{ d = trySafely(blockD) },
			{ e = trySafely(blockE) },
			{ f = trySafely(blockF) },
			{ g = trySafely(blockG) },
			{ h = trySafely(blockH) },
			{ i = trySafely(blockI) },
			{ j = trySafely(blockJ) }
		)
		return (a, b, c, d, e, f, g, h, i, j)
	}

	@discardableResult
	public func asyncExecuteAndWait<A, B, C, D, E, F, G, H, I>(
		_ blockA: @escaping () throws -> A,
		_ blockB: @escaping () throws -> B,
		_ blockC: @escaping () throws -> C,
		_ blockD: @escaping () throws -> D,
		_ blockE: @escaping () throws -> E,
		_ blockF: @escaping () throws -> F,
		_ blockG: @escaping () throws -> G,
		_ blockH: @escaping () throws -> H,
		_ blockI: @escaping () throws -> I
	) -> (A, B, C, D, E, F, G, H, I) {
		var a: A!, b: B!, c: C!, d: D!, e: E!, f: F!, g: G!, h: H!, i: I!
		asyncExecuteAndWait(
			{ a = trySafely(blockA) },
			{ b = trySafely(blockB) },
			{ c = trySafely(blockC) },
			{ d = trySafely(blockD) },
			{ e = trySafely(blockE) },
			{ f = trySafely(blockF) },
			{ g = trySafely(blockG) },
			{ h = trySafely(blockH) },
			{ i = trySafely(blockI) }
		)
		return (a, b, c, d, e, f, g, h, i)
	}

	@discardableResult
	public func asyncExecuteAndWait<A, B, C, D, E, F, G, H>(
		_ blockA: @escaping () throws -> A,
		_ blockB: @escaping () throws -> B,
		_ blockC: @escaping () throws -> C,
		_ blockD: @escaping () throws -> D,
		_ blockE: @escaping () throws -> E,
		_ blockF: @escaping () throws -> F,
		_ blockG: @escaping () throws -> G,
		_ blockH: @escaping () throws -> H
	) -> (A, B, C, D, E, F, G, H) {
		var a: A!, b: B!, c: C!, d: D!, e: E!, f: F!, g: G!, h: H!
		asyncExecuteAndWait(
			{ a = trySafely(blockA) },
			{ b = trySafely(blockB) },
			{ c = trySafely(blockC) },
			{ d = trySafely(blockD) },
			{ e = trySafely(blockE) },
			{ f = trySafely(blockF) },
			{ g = trySafely(blockG) },
			{ h = trySafely(blockH) }
		)
		return (a, b, c, d, e, f, g, h)
	}

	@discardableResult
	public func asyncExecuteAndWait<A, B, C, D, E, F, G>(
		_ blockA: @escaping () throws -> A,
		_ blockB: @escaping () throws -> B,
		_ blockC: @escaping () throws -> C,
		_ blockD: @escaping () throws -> D,
		_ blockE: @escaping () throws -> E,
		_ blockF: @escaping () throws -> F,
		_ blockG: @escaping () throws -> G
	) -> (A, B, C, D, E, F, G) {
		var a: A!, b: B!, c: C!, d: D!, e: E!, f: F!, g: G!
		asyncExecuteAndWait(
			{ a = trySafely(blockA) },
			{ b = trySafely(blockB) },
			{ c = trySafely(blockC) },
			{ d = trySafely(blockD) },
			{ e = trySafely(blockE) },
			{ f = trySafely(blockF) },
			{ g = trySafely(blockG) }
		)
		return (a, b, c, d, e, f, g)
	}

	@discardableResult
	public func asyncExecuteAndWait<A, B, C, D, E, F>(
		_ blockA: @escaping () throws -> A,
		_ blockB: @escaping () throws -> B,
		_ blockC: @escaping () throws -> C,
		_ blockD: @escaping () throws -> D,
		_ blockE: @escaping () throws -> E,
		_ blockF: @escaping () throws -> F
	) -> (A, B, C, D, E, F) {
		var a: A!, b: B!, c: C!, d: D!, e: E!, f: F!
		asyncExecuteAndWait(
			{ a = trySafely(blockA) },
			{ b = trySafely(blockB) },
			{ c = trySafely(blockC) },
			{ d = trySafely(blockD) },
			{ e = trySafely(blockE) },
			{ f = trySafely(blockF) }
		)
		return (a, b, c, d, e, f)
	}

	@discardableResult
	public func asyncExecuteAndWait<A, B, C, D, E>(
		_ blockA: @escaping () throws -> A,
		_ blockB: @escaping () throws -> B,
		_ blockC: @escaping () throws -> C,
		_ blockD: @escaping () throws -> D,
		_ blockE: @escaping () throws -> E
	) -> (A, B, C, D, E) {
		var a: A!, b: B!, c: C!, d: D!, e: E!
		asyncExecuteAndWait(
			{ a = trySafely(blockA) },
			{ b = trySafely(blockB) },
			{ c = trySafely(blockC) },
			{ d = trySafely(blockD) },
			{ e = trySafely(blockE) }
		)
		return (a, b, c, d, e)
	}

	@discardableResult
	public func asyncExecuteAndWait<A, B, C, D>(
		_ blockA: @escaping () throws -> A,
		_ blockB: @escaping () throws -> B,
		_ blockC: @escaping () throws -> C,
		_ blockD: @escaping () throws -> D
		) -> (A, B, C, D) {
	var a: A!, b: B!, c: C!, d: D!
		asyncExecuteAndWait(
			{ a = trySafely(blockA) },
			{ b = trySafely(blockB) },
			{ c = trySafely(blockC) },
			{ d = trySafely(blockD) }
		)
		return (a, b, c, d)
	}

	@discardableResult
	public func asyncExecuteAndWait<A, B, C>(
		_ blockA: @escaping () throws -> A,
		_ blockB: @escaping () throws -> B,
		_ blockC: @escaping () throws -> C
	) -> (A, B, C) {
		var a: A!, b: B!, c: C!
		asyncExecuteAndWait(
			{ a = trySafely(blockA) },
			{ b = trySafely(blockB) },
			{ c = trySafely(blockC) }
		)
		return (a, b, c)
	}

	@discardableResult
	public func asyncExecuteAndWait<A, B>(
		_ blockA: @escaping () throws -> A,
		_ blockB: @escaping () throws -> B
	) -> (A, B) {
		var a: A!, b: B!
		asyncExecuteAndWait(
			{ a = trySafely(blockA) },
			{ b = trySafely(blockB) }
		)
		return (a, b)
	}
}
