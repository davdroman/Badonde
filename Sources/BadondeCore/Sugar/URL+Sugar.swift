import Foundation
import SwiftCLI

extension URL {
	init(scheme: String, host: String, path: String, queryItems: [URLQueryItem]? = nil) throws {
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

	init(scheme: String, host: String, path: String, queryItems: [URLQueryItem?]?) throws {
		try self.init(scheme: scheme, host: host, path: path, queryItems: queryItems?.compactMap { $0 })
	}
}

extension URL {
	enum Error {
		case invalidURL(URLComponents)
	}
}

extension URL.Error: ProcessError {
	var message: String? {
		switch self {
		case .invalidURL(let urlComponents):
			return ["☛ URL formatting failed. Info:", "☛ \(urlComponents)"].joined(separator: "\n")
		}
	}
}
