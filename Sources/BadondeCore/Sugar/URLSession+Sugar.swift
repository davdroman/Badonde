import Foundation

extension URLSession {
	func synchronousDataTask(with request: URLRequest) -> (data: Data?, response: URLResponse?, error: Error?) {
		let semaphore = DispatchSemaphore(value: 0)
		var result: (Data?, URLResponse?, Error?)?
		let dataTask = self.dataTask(with: request) { data, response, error in
			result = (data: data, response: response, error: error)
			semaphore.signal()
		}
		dataTask.resume()
		semaphore.wait()
		guard let unwrappedResult = result else {
			fatalError("Synchronous request finished without a response")
		}
		return unwrappedResult
	}
}
