import Foundation

extension AppifyCommand {
	enum Error {
		case noAppTemplateAvailable
		case appCompilationFailed
	}
}

extension AppifyCommand.Error: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .noAppTemplateAvailable:
			return "No .app templates available on GitHub, please contact d@vidroman.dev"
		case .appCompilationFailed:
			return "AppleScript app compilation failed"
		}
	}
}
