import Foundation

extension AppifyCommand {
	enum Error {
		case noAppTemplateAvailable
	}
}

extension AppifyCommand.Error: Swift.Error {
	var localizedDescription: String {
		switch self {
		case .noAppTemplateAvailable:
			return "No .app templates available on GitHub, please contact d@vidroman.dev"
		}
	}
}
