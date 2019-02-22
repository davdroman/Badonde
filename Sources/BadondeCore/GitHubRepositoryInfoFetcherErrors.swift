import SwiftCLI

extension GitHubRepositoryInfoFetcher {
	enum Error {
		case invalidEndpointURLFormat(Any.Type)
		case githubConnectionFailed(Swift.Error)
		case noDataReceived(Any.Type)
	}
}

extension GitHubRepositoryInfoFetcher.Error: ProcessError {
	var message: String? {
		switch self {
		case .invalidEndpointURLFormat(let modelType):
			return "☛ GitHub API endpoint URL formatting failed for type '\(modelType)'"
		case .githubConnectionFailed(let error):
			return "☛ GitHub API call failed with error: \(error)"
		case .noDataReceived(let modelType):
			return "☛ No data received for GitHub API call for type '\(modelType)'"
		}
	}
}
