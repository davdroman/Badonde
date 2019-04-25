import Foundation

public protocol BranchInteractor {
	func getAllBranches(from source: Branch.Source) throws -> String
}

public struct Branch: Equatable {
	public enum Source: Equatable {
		case local
		case remote(Remote)

		public var remote: Remote? {
			switch self {
			case .local:
				return nil
			case .remote(let remote):
				return remote
			}
		}
	}

	public let name: String
	public var source: Source

	public var fullName: String {
		let prefix = source.remote.map { $0.name + "/" } ?? ""
		return prefix + name
	}

	public init(name: String, source: Source) throws {
		guard name.rangeOfCharacter(from: .whitespaces) == nil else {
			throw Error.nameContainsInvalidCharacters
		}

		switch source {
		case .local:
			self.name = name
		case .remote(let remote):
			if let prefixRange = name.range(of: remote.name + "/") {
				self.name = name.replacingCharacters(in: ..<prefixRange.upperBound, with: "")
			} else {
				self.name = name
			}
		}

		self.source = source
	}
}

extension Branch {
	public static func getAll(from source: Branch.Source, interactor: BranchInteractor? = nil) throws -> [Branch] {
		let interactor = interactor ?? SwiftCLI()

		return try interactor.getAllBranches(from: source)
			.components(separatedBy: "\n")
			.compactMap { try? Branch(name: $0, source: source) }
	}
}
