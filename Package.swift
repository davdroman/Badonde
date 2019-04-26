// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Badonde",
	platforms: [
		.macOS(.v10_12)
	],
	products: [
		.executable(name: "badonde", targets: ["Badonde"]),
		.executable(name: "burgh", targets: ["Burgh"])
	],
	dependencies: [
		.package(
			url: "https://github.com/DavdRoman/SwiftCLI",
			.branch("master")
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
			dependencies: [
				"SwiftCLI",
				"SwiftyStringScore",
				"CLISpinner",
				"Git",
				"GitHub",
				"Jira",
				"Sugar"
			]
		),
		.target(
			name: "Burgh",
			dependencies: ["BadondeCore"]
		),
		.target(
			name: "Git",
			dependencies: ["SwiftCLI"]
		),
		.target(
			name: "GitHub",
			dependencies: ["Git", "Sugar"]
		),
		.testTarget(
			name: "GitTests",
			dependencies: ["Git", "TestSugar"]
		),
		.testTarget(
			name: "GitHubTests",
			dependencies: ["GitHub"]
		),
		.target(
			name: "TestSugar"
		),
		.target(
			name: "Jira",
			dependencies: ["Sugar"]
		),
		.target(
			name: "Sugar"
		)
	]
)

