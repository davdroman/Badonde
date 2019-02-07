//
//  ClearCommand.swift
//  BadondeCore
//
//  Created by David Roman on 07/02/2019.
//

import Foundation
import SwiftCLI

class ClearCommand: Command {
	let name = "clear"
	let shortDescription = "Clears credentials"

	func execute() throws {
		let accessTokenStore = AccessTokenStore()
		guard accessTokenStore.config != nil else {
			return
		}
		accessTokenStore.config = nil
	}
}
