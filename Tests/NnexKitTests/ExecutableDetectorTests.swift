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
        let sut = makeSUT()
        let manifest = TestData.multipleExecutables
        let result = try sut.getExecutables(packageManifestContent: manifest)
        
        #expect(result == ["FirstExecutable", "SecondExecutable"])
    }

    @Test("Throws error when no executables are present")
    func throwsWhenNoExecutables() {
        let sut = makeSUT()
        let manifest = TestData.noExecutables
        
        #expect(throws: NnexError.missingExecutable) {
            _ = try sut.getExecutables(packageManifestContent: manifest)
        }
    }

    @Test("Returns an array with a single executable when only one executable is present")
    func parsesSingleExecutable() throws {
        let sut = makeSUT()
        let manifest = TestData.singleExecutable
        let result = try sut.getExecutables(packageManifestContent: manifest)
        
        #expect(result == ["SingleExecutable"])
    }

    @Test("Ignores malformed executable entries and returns valid ones")
    func ignoresMalformedEntries() throws {
        let sut = makeSUT()
        let manifest = TestData.malformedExecutable
        let result = try sut.getExecutables(packageManifestContent: manifest)
        
        #expect(result == ["ValidExecutable"])
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


// MARK: - SUT
private extension ExecutableDetectorTests {
    func makeSUT() -> ExecutableDetector.Type {
        return ExecutableDetector.self
    }
}
