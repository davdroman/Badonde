import Foundation
import Sugar

extension Authorization {
	public final class API: GitHub.API {
		enum Constant {
			static let githubOTPHeaderKey = "X-GitHub-OTP"
		}

		public init(username: String, password: String) {
			super.init(authorization: .basic(username: username, password: password))
		}

		struct CreateAuthorizationBody: Codable {
			var scopes: [Scope]
			var note: String
		}

		public func createAuthorization(
			scopes: [Scope],
			note: String,
			oneTimePassword: @autoclosure () -> String
		) throws -> GitHub.Authorization {
			var currentNoteSuffixIndex = 1
			var otpHeader: HTTPHeader?

			while true {
				let noteSuffix = currentNoteSuffixIndex > 1 ? " \(currentNoteSuffixIndex)" : ""
				let body = CreateAuthorizationBody(scopes: scopes, note: note + noteSuffix)

				do {
					return try post(
						endpoint: "/authorizations",
						headers: [otpHeader].compacted(),
						body: body,
						responseType: GitHub.Authorization.self
					)
				} catch let error {
					guard case let GitHub.API.Error.http(response, _) = error else {
						throw error
					}

					switch response.statusCode {
					case 422: // already exists
						currentNoteSuffixIndex += 1
						continue
					case 401: // OTP required
						guard
							let githubOTPHeaderValue = response.allHeaderFields[Constant.githubOTPHeaderKey] as? String,
							githubOTPHeaderValue.hasPrefix("required")
						else {
							fallthrough
						}
						otpHeader = (field: Constant.githubOTPHeaderKey, value: oneTimePassword())
						continue
					default:
						throw error
					}
				}
			}
		}
	}
}
