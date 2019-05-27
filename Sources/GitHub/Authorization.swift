import Foundation

public struct Authorization: Decodable {
	public enum Scope: String, Codable {
		case repo
	}

	public var scopes: [Scope]
	public var token: String
	public var note: String
}
