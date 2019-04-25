import Foundation

public protocol CommitInteractor {
	func count(baseBranch: String, targetBranch: String, after date: Date?) throws -> Int
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
