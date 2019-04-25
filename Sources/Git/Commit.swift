import Foundation

public protocol CommitInteractor {
	func count(baseBranches: [String], targetBranch: String, after date: Date?) throws -> String
}

public struct Commit: Equatable {
	public var hash: String
	public var author: User
	public var date: Date
	public var subject: String
	public var body: String

	public init(rawCommitContent: String) throws {
		let boundary = "\n---BADONDE-BOUNDARY---\n"
		let commitComponents = rawCommitContent.components(separatedBy: boundary)

		guard
			let hash = commitComponents.first,
			let authorName = commitComponents.dropFirst().first,
			let authorEmail = commitComponents.dropFirst(2).first,
			let unixDate = commitComponents.dropFirst(3).first.flatMap(TimeInterval.init),
			let subject = commitComponents.dropFirst(4).first,
			let body = commitComponents.dropFirst(5).first
		else {
			throw Error.missingProperty
		}

		self.hash = hash
		self.author = User(name: authorName, email: authorEmail)
		self.date = Date(timeIntervalSince1970: unixDate)
		self.subject = subject
		self.body = body
	}
}

extension Commit {
	public static func count(baseBranch: Branch, targetBranch: Branch, after date: Date? = nil, interactor: CommitInteractor? = nil) throws -> Int {
		let interactor = interactor ?? SwiftCLI()
		let commitCountRaw = try interactor.count(baseBranches: [baseBranch.fullName], targetBranch: targetBranch.name, after: date)
		guard let commitCount = Int(commitCountRaw) else {
			throw Error.numberNotFound
		}
		return commitCount
	}

	public static func count(baseBranches: [Branch], targetBranch: Branch, after date: Date? = nil, interactor: CommitInteractor? = nil) throws -> [(Branch, Int)] {
		let interactor = interactor ?? SwiftCLI()
		let commitCountRaw = try interactor.count(baseBranches: baseBranches.map { $0.fullName }, targetBranch: targetBranch.name, after: date)
		return try commitCountRaw
			.components(separatedBy: "\n")
			.enumerated()
			.map {
				guard let count = Int($0.element) else {
					throw Error.numberNotFound
				}
				return (baseBranches[$0.offset], count)
			}
	}
}
