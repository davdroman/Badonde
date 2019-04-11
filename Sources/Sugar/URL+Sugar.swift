import Foundation

extension URL {
	public static func homeDirectory() throws -> URL {
		guard #available(OSX 10.12, *) else {
			throw Error.minimumVersionOfMacOSRequired10_2
		}

		return FileManager().homeDirectoryForCurrentUser
	}

	public init(scheme: String, host: String, path: String, queryItems: [URLQueryItem]? = nil) throws {
		var urlComponents = URLComponents()
		urlComponents.scheme = scheme
		urlComponents.host = host
		urlComponents.path = path
		urlComponents.queryItems = queryItems?.nilIfEmpty
		guard let url = urlComponents.url else {
			throw Error.invalidURL(urlComponents)
		}
		self = url
	}

	public init(scheme: String, host: String, path: String, queryItems: [URLQueryItem?]?) throws {
		try self.init(scheme: scheme, host: host, path: path, queryItems: queryItems?.compactMap { $0 })
	}
}

extension URL {
	public enum Error {
		case minimumVersionOfMacOSRequired10_2
		case invalidURL(URLComponents)
	}
}

extension URL.Error: Swift.Error {
	public var localizedDescription: String {
		switch self {
		case .minimumVersionOfMacOSRequired10_2:
			return "This command is not supported on versions of macOS lower than 10.12"
		case .invalidURL(let urlComponents):
			return ["URL formatting failed. Info:", "\(urlComponents)"].joined(separator: "\n")
		}
	}
}
