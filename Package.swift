// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "nnex",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "NnexKit",
            targets: ["NnexKit"]
        ),
        .executable(
            name: "nnex",
            targets: ["nnex"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
        .package(url: "https://github.com/kareman/SwiftShell", from: "5.0.0"),
        .package(url: "https://github.com/nikolainobadi/NnGitKit.git", from: "1.0.0"),
        .package(url: "https://github.com/nikolainobadi/SwiftPicker.git", from: "0.8.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/nikolainobadi/NnSwiftDataKit.git", branch: "main")
    ],
    targets: [
        .target(
            name: "NnexKit",
            dependencies: [
                "SwiftShell",
                "NnSwiftDataKit",
                .product(name: "GitShellKit", package: "NnGitKit"),
            ]
        ),
        .executableTarget(
            name: "nnex",
            dependencies: [
                "Files",
                "NnexKit",
                "SwiftPicker",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Resources/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "nnexTests",
            dependencies: ["nnex"]
        ),
        .testTarget(
            name: "NnexKitTests",
            dependencies: ["NnexKit"]
        )
    ]
)
