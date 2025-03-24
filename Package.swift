// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "nnex",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "nnex",
            targets: ["nnex"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nikolainobadi/NnexKit.git", branch: "main"),
        .package(url: "https://github.com/nikolainobadi/SwiftPicker.git", from: "0.8.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "nnex",
            dependencies: [
                "SwiftPicker",
                .product(name: "NnexKit", package: "NnexKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            linkerSettings: [
                /// Linker settings to embed the Info.plist file directly into the binary.
                /// This is necessary to allow the Swift package to utilize SwiftData,
                /// as SwiftData requires a bundle identifier to function properly.
                /// - The `-Xlinker` flag passes the following argument to the linker.
                /// - The `-sectcreate` flag creates a new section in the binary.
                /// - `__TEXT` and `__info_plist` specify the segment and section names.
                /// - `Resources/Info.plist` is the path to the Info.plist file to embed.
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
            dependencies: [
                "nnex",
                .product(name: "NnexSharedTestHelpers", package: "NnexKit")
            ]
        )
    ]
)
