import Foundation

extension URLSession {
	public func synchronousDataTask(with request: URLRequest) -> Result<(data: Data, response: URLResponse), Error> {
		let semaphore = DispatchSemaphore(value: 0)
		var possibleResult: Result<(data: Data, response: URLResponse), Error>?
		let dataTask = self.dataTask(with: request) { result in
			possibleResult = result
			semaphore.signal()
		}
		dataTask.resume()
		semaphore.wait()
		guard let unwrappedResult = possibleResult else {
			fatalError("Synchronous request finished without a response")
		}
		return unwrappedResult
	}

	func dataTask(with request: URLRequest, completionHandler: @escaping (Result<(data: Data, response: URLResponse), Error>) -> Void) -> URLSessionDataTask {
		return dataTask(with: request) { data, urlResponse, error in
			if let error = error {
				completionHandler(.failure(error))
			} else if let data = data, let urlResponse = urlResponse {
				completionHandler(.success((data, urlResponse)))
			} else {
				fatalError("Impossible!")
			}
		}
	}
}
