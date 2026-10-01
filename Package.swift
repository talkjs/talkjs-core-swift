// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "talkjs-core-swift",
    platforms: [
        .macOS(.v11),
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "talkjs-core-swift",
            targets: ["talkjs-core-swift"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .binaryTarget(
            name: "BinaryCore",
            url: "https://github.com/talkjs/talkjs-core-swift/releases/download/TalkJSCore_v0.2.0-alpha/TalkJSCoreRelease.zip",
            checksum: "641aa0c52bde0ca31676a312b8c3bfbd7586cae1609d3c553e4f550cc4b9a27d"
        ),
        .target(
            name: "talkjs-core-swift",
            dependencies: ["BinaryCore"]
        )
    ],
    swiftLanguageModes: [.v6]
)
