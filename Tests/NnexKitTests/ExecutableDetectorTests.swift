//
//  ExecutableDetectorTests.swift
//  NnexKit
//
//  Created by Nikolai Nobadi on 3/25/25.
//

import Testing
@testable import NnexKit

struct ExecutableDetectorTests {
    @Test("Returns an array of executable names when multiple executables are present")
    func parsesMultipleExecutables() throws {
        let executables = try ExecutableDetector.getExecutables(packageManifestContent: TestData.multipleExecutables)
        #expect(executables == ["FirstExecutable", "SecondExecutable"])
    }

    @Test("Throws error when no executables are present")
    func throwsWhenNoExecutables() {
        #expect(throws: NnexError.missingExecutable) {
            _ = try ExecutableDetector.getExecutables(packageManifestContent: TestData.noExecutables)
        }
    }

    @Test("Returns an array with a single executable when only one executable is present")
    func parsesSingleExecutable() throws {
        let executables = try ExecutableDetector.getExecutables(packageManifestContent: TestData.singleExecutable)
        #expect(executables == ["SingleExecutable"])
    }

    @Test("Ignores malformed executable entries and returns valid ones")
    func ignoresMalformedEntries() throws {
        let executables = try ExecutableDetector.getExecutables(packageManifestContent: TestData.malformedExecutable)
        #expect(executables == ["ValidExecutable"])
    }
}

// MARK: - Test Data
private extension ExecutableDetectorTests {
    enum TestData {
        static let multipleExecutables = """
        // swift-tools-version:5.9
        import PackageDescription

        let package = Package(
            name: "MyTestPackage",
            products: [
                .library(
                    name: "MyLibrary",
                    targets: ["MyLibrary"]
                ),
                .executable(
                    name: "FirstExecutable",
                    targets: ["FirstTarget"]
                ),
                .executable(
                    name: "SecondExecutable",
                    targets: ["SecondTarget"]
                ),
            ],
            targets: [
                .target(
                    name: "MyLibrary",
                    dependencies: []
                ),
                .executableTarget(
                    name: "FirstTarget",
                    dependencies: []
                ),
                .executableTarget(
                    name: "SecondTarget",
                    dependencies: []
                ),
            ]
        )
        """

        static let noExecutables = """
        // swift-tools-version:5.9
        import PackageDescription

        let package = Package(
            name: "MyTestPackage",
            products: [
                .library(
                    name: "MyLibrary",
                    targets: ["MyLibrary"]
                )
            ],
            targets: [
                .target(
                    name: "MyLibrary",
                    dependencies: []
                )
            ]
        )
        """

        static let singleExecutable = """
        // swift-tools-version:5.9
        import PackageDescription

        let package = Package(
            name: "MyTestPackage",
            products: [
                .executable(
                    name: "SingleExecutable",
                    targets: ["SingleTarget"]
                )
            ],
            targets: [
                .executableTarget(
                    name: "SingleTarget",
                    dependencies: []
                )
            ]
        )
        """

        static let malformedExecutable = """
        // swift-tools-version:5.9
        import PackageDescription

        let package = Package(
            name: "MyTestPackage",
            products: [
                .executable(
                    name: "ValidExecutable",
                    targets: ["ValidTarget"]
                ),
                .executable(name: , targets: ["MalformedTarget"])
            ],
            targets: [
                .executableTarget(
                    name: "ValidTarget",
                    dependencies: []
                )
            ]
        )
        """
    }
}
