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
        .library(
            name: "NnexKit",
            targets: ["NnexKit"]
        ),
        .library(
            name: "NnexSharedTestHelpers",
            targets: ["NnexSharedTestHelpers"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
        .package(url: "https://github.com/nikolainobadi/NnGitKit.git", from: "0.6.0"),
        .package(url: "https://github.com/nikolainobadi/NnShellKit.git", branch: "refactor-mock-shell"),
//        .package(url: "https://github.com/nikolainobadi/NnShellKit.git", from: "1.0.0"),
        .package(url: "https://github.com/nikolainobadi/NnSwiftDataKit", from: "0.5.0"),
        .package(url: "https://github.com/nikolainobadi/SwiftPicker.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "nnex",
            dependencies: [
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
        .target(
            name: "NnexKit",
            dependencies: [
                "Files",
                "NnShellKit",
                "NnSwiftDataKit",
                .product(name: "GitShellKit", package: "NnGitKit"),
            ]
        ),
        .target(
            name: "NnexSharedTestHelpers",
            dependencies: [
                "NnexKit"
            ]
        ),
        .testTarget(
            name: "nnexTests",
            dependencies: [
                "nnex",
                "NnexSharedTestHelpers"
            ]
        ),
        .testTarget(
            name: "NnexKitTests",
            dependencies: [
                "NnexKit",
                "NnexSharedTestHelpers"
            ]
        )
    ]
)
