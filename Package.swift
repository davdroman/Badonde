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
		.executable(name: "badonde", targets: ["Badonde"]),
	],
	dependencies: [
		.package(url: "https://github.com/DavdRoman/CLISpinner", .branch("master")),
		.package(url: "https://github.com/DavdRoman/SwiftyStringScore", .branch("master")),
		.package(url: "https://github.com/DavdRoman/SwiftCLI", .branch("master")),
		.package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: Version(1, 0, 0)),
	],
	targets: [
		.target(name: "Badonde", dependencies: ["BadondeCore"]),
		.target(
			name: "BadondeCore",
			dependencies: [
				"BadondeKit",
				"Configuration",
				"SwiftCLI",
				"SwiftyStringScore",
				"CLISpinner",
				"Git",
				"GitHub",
				"Jira",
				"Sugar",
			]
		),
		.target(
			name: "BadondeKit",
			dependencies: [
				"CryptoSwift",
				"Git",
				"GitHub",
				"Jira",
				"Sugar",
			]
		),
		.target(name: "Configuration", dependencies: ["Sugar"]),
		.target(name: "Git", dependencies: ["SwiftCLI"]),
		.target(name: "GitHub", dependencies: ["Git", "Sugar"]),
		.target(name: "Jira", dependencies: ["Sugar"]),
		.target(name: "Sugar"),
		.target(name: "TestSugar"),

		.testTarget(name: "BadondeKitTests", dependencies: ["BadondeKit"]),
		.testTarget(name: "ConfigurationTests", dependencies: ["Configuration", "TestSugar"]),
		.testTarget(name: "GitTests", dependencies: ["Git", "TestSugar"]),
		.testTarget(name: "GitHubTests", dependencies: ["GitHub"]),
	]
)
