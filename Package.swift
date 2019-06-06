// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Badonde",
	platforms: [
		.macOS(.v10_13)
	],
	products: [
		.library(name: "BadondeKit", type: .dynamic, targets: ["BadondeKit"]),
		.executable(name: "badonde", targets: ["CLI"]),
	],
	dependencies: [
		.package(url: "https://github.com/DavdRoman/CLISpinner", .branch("master")),
		.package(url: "https://github.com/DavdRoman/SwiftCLI", .branch("master")),
		.package(url: "https://github.com/DavdRoman/SwiftyStringScore", .branch("master")),
	],
	targets: [
		.target(
			name: "CLI",
			dependencies: [
				"BadondeKit",
				"CLISpinner",
				"Configuration",
				"Core",
				"Git",
				"GitHub",
				"Jira",
				"Sugar",
				"SwiftCLI",
			]
		),
		.target(
			name: "Core",
			dependencies: [
				"BadondeKit",
				"Configuration",
				"SwiftCLI",
			]
		),
		.target(
			name: "BadondeKit",
			dependencies: [
				"Git",
				"GitHub",
				"Jira",
				"Sugar",
				"SwiftCLI",
			]
		),
		.target(name: "Configuration", dependencies: ["Sugar"]),
		.target(name: "Firebase", dependencies: ["Sugar"]),
		.target(name: "Git", dependencies: ["SwiftCLI"]),
		.target(name: "GitHub", dependencies: ["Git", "Sugar"]),
		.target(name: "Jira", dependencies: ["Sugar"]),
		.target(name: "Sugar", dependencies: ["SwiftyStringScore"]),
		.target(name: "TestSugar"),

		.testTarget(name: "BadondeKitTests", dependencies: ["BadondeKit"]),
		.testTarget(name: "ConfigurationTests", dependencies: ["Configuration", "TestSugar"]),
		.testTarget(name: "GitTests", dependencies: ["Git", "TestSugar"]),
		.testTarget(name: "GitHubTests", dependencies: ["GitHub"]),
	]
)
