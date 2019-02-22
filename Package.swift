// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Badonde",
	products: [
		.executable(name: "badonde", targets: ["Badonde"]),
		.executable(name: "burgh", targets: ["Burgh"])
	],
	dependencies: [
		.package(
			url: "https://github.com/jakeheis/SwiftCLI",
			from: "5.0.0"
		),
		.package(
			url: "https://github.com/DavdRoman/SwiftyStringScore",
			.branch("master")
		),
		.package(
			url: "https://github.com/DavdRoman/CLISpinner",
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
			dependencies: ["SwiftCLI", "SwiftyStringScore", "CLISpinner"]
		),
		.testTarget(
			name: "BadondeCoreTests",
			dependencies: ["BadondeCore"]
		),
		.target(
			name: "Burgh",
			dependencies: ["BadondeCore"]
		)
	]
)

