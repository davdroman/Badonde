// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Badonde",
	dependencies: [
		.package(
			url: "https://github.com/nvzqz/FileKit",
			from: "5.0.0"
		),
		.package(
			url: "https://github.com/JohnSundell/ShellOut",
			from: "2.1.0"
		),
		.package(
			url: "https://github.com/Moya/Moya",
			from: "10.0.1"
		)
	],
	targets: [
		.target(
			name: "Badonde",
			dependencies: ["BadondeCore"]
		),
		.target(
			name: "BadondeCore",
			dependencies: ["FileKit", "ShellOut", "Moya"]
		),
		.testTarget(
			name: "BadondeTests",
			dependencies: ["BadondeCore", "FileKit"]
		)
	]
)

