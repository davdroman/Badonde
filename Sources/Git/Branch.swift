import Foundation

protocol BranchInteractor {
	func getCurrentBranch(atPath path: String) throws -> String
	func getAllBranches(from source: Branch.Source, atPath path: String) throws -> String
}

public struct Branch: Equatable, Codable {
	public enum Source: Equatable, RawRepresentable {
		case local
		case remote(Remote)

		public init?(rawValue: String) {
			let components = rawValue.components(separatedBy: .whitespaces)
			let component1 = components.first
			let component2 = components.dropFirst().first
			let component3 = components.dropFirst(2).first

			switch (component1, component2, component3) {
			case ("local", _, _):
				self = .local
			case let ("remote", name?, urlString?):
				guard let url = URL(string: urlString) else {
					return nil
				}
				self = .remote(Remote(name: name, url: url))
			default:
				return nil
			}
		}

		public var rawValue: String {
			switch self {
			case .local:
				return "local"
			case .remote(let remote):
				return ["remote", remote.name, remote.url.absoluteString].joined(separator: " ")
			}
		}

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

extension Branch.Source: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawValue = try container.decode(String.self)
		guard let instance = Branch.Source(rawValue: rawValue) else {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Raw value '\(rawValue)' is not a valid 'Branch.Source' raw value type"
			)
		}
		self = instance
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}

extension Branch {
	static var interactor: BranchInteractor = SwiftCLI()

	public static func current(atPath path: String) throws -> Branch {
		return try Branch(name: interactor.getCurrentBranch(atPath: path), source: .local)
	}

	public static func getAll(from source: Branch.Source, atPath path: String) throws -> [Branch] {
		return try interactor.getAllBranches(from: source, atPath: path)
			.components(separatedBy: "\n")
			.compactMap { try? Branch(name: $0, source: source) }
	}

	public func isAhead(of remote: Remote, atPath path: String) throws -> Bool {
		var remoteBranch = self
		remoteBranch.source = .remote(remote)

		return try Commit.count(baseBranch: remoteBranch, targetBranch: self, atPath: path) > 0
	}

	public func parent(for remote: Remote, defaultBranch: Branch, atPath path: String) throws -> Branch {
		let allRemoteBranches = try Branch.getAll(from: .remote(remote), atPath: path)

		let recentDate = Date(timeIntervalSinceNow: -2_592_000) // 1 month ago

		let latestRecentCommitHashes = try Commit.latestHashes(
			branches: allRemoteBranches,
			after: recentDate,
			atPath: path
		)

		let recentRemoteBranches = allRemoteBranches.enumerated()
			.filter { !latestRecentCommitHashes[$0.offset].isEmpty }
			.map { $0.element }

		let commitsAndBranches = try Commit.count(
			baseBranches: recentRemoteBranches,
			targetBranch: self,
			after: recentDate,
			atPath: path
		)

		let branchesWithLowestEqualCommitCount = commitsAndBranches
			.filter { $0.1 > 0 }
			.sorted { $0.1 < $1.1 }
			.reduce([(Branch, Int)]()) { result, branchAndCommits -> [(Branch, Int)] in
				guard let lastBranchAndCommits = result.last, lastBranchAndCommits.1 != branchAndCommits.1 else {
					return result + [branchAndCommits]
				}
				return result
			}
			.map { $0.0 }

		guard
			!branchesWithLowestEqualCommitCount.contains(where: { $0.name == defaultBranch.name }),
			let parentBranch = branchesWithLowestEqualCommitCount.first
		else {
			return defaultBranch
		}

		return parentBranch
	}
}

extension Branch {
	public enum Error {
		case nameContainsInvalidCharacters
	}
}

extension Branch.Error: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .nameContainsInvalidCharacters:
			return "Name contains invalid characters"
		}
	}
}
