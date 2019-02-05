//
//  URL+Sugar.swift
//  BadondeCore
//
//  Created by David Roman on 05/02/2019.
//

import Foundation

extension URL {
	init?(scheme: String, host: String, path: String, queryItems: [URLQueryItem]?) {
		var urlComponents = URLComponents()
		urlComponents.scheme = scheme
		urlComponents.host = host
		urlComponents.path = path
		urlComponents.queryItems = queryItems?.nilIfEmpty
		guard let url = urlComponents.url else {
			return nil
		}
		self = url
	}

	init?(scheme: String, host: String, path: String, queryItems: [URLQueryItem?]?) {
		self.init(scheme: scheme, host: host, path: path, queryItems: queryItems?.compactMap { $0 })
	}
}
