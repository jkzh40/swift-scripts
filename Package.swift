// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftScripts",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        // MARK: Executables

        // MARK: Libraries
        .target(
            name: "Common",
            dependencies: [
                "Figlet",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "Figlet",
            resources: [
                .process("Fonts")
            ]
        ),

        // MARK: Tests
        .testTarget(
            name: "CommonTests",
            dependencies: [
                "Common"
            ]
        ),
        .testTarget(
            name: "FigletTests",
            dependencies: [
                "Figlet"
            ]
        ),
    ]
)
