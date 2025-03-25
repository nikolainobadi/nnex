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
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Resources/Info.plist"
                ])
            ]
        )
    ]
)
