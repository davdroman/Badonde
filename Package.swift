// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Badonde",
	dependencies: [
		.package(
			url: "https://github.com/jakeheis/SwiftCLI",
			from: "5.0.0"
		),
		.package(
			url: "https://github.com/antitypical/Result",
			from: "4.0.0"
		),
		.package(
			url: "https://github.com/DavdRoman/SwiftyStringScore",
			.branch("master")
		)
	],
	targets: [
		.target(
			name: "Badonde",
			dependencies: ["BadondeCore"]
		),
		.target(
			name: "BadondeCore",
			dependencies: ["SwiftCLI", "Result", "SwiftyStringScore"]
		)
	]
)

