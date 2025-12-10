////
////  ExecutableNameResolverTests.swift
////  nnex
////
////  Created by Nikolai Nobadi on 8/26/25.
////
//
//import Testing
//import Foundation
//import NnexSharedTestHelpers
//@testable import nnex
//
//struct ExecutableNameResolverTests {
//    private let projectName = "testProject-executableResolver"
//}
//
//
//// MARK: - Tests
//extension ExecutableNameResolverTests {
//    @Test("Throws error when Package.swift is missing")
//    func throwsErrorWhenPackageSwiftMissing() throws {
//        let directory = MockDirectory(path: "/test/project")
//
//        #expect(throws: ExecutableNameResolverError.missingPackageSwift(path: directory.path)) {
//            try ExecutableNameResolver.getExecutableNames(from: directory)
//        }
//    }
//
//    @Test("Throws error when Package.swift cannot be read")
//    func throwsErrorWhenPackageSwiftCannotBeRead() throws {
//        let directory = MockDirectory(path: "/test/project", containedFiles: ["Package.swift"])
//
//        #expect(throws: (any Error).self) {
//            try ExecutableNameResolver.getExecutableNames(from: directory)
//        }
//    }
//
//    @Test("Throws error when Package.swift is empty")
//    func throwsErrorWhenPackageSwiftIsEmpty() throws {
//        let directory = MockDirectory(path: "/test/project")
//        try directory.createFile(named: "Package.swift", contents: "")
//
//        #expect(throws: ExecutableNameResolverError.emptyPackageSwift) {
//            try ExecutableNameResolver.getExecutableNames(from: directory)
//        }
//    }
//
//    @Test("Throws error when Package.swift contains only whitespace")
//    func throwsErrorWhenPackageSwiftContainsOnlyWhitespace() throws {
//        let directory = MockDirectory(path: "/test/project")
//        try directory.createFile(named: "Package.swift", contents: "   \n\t  \n   ")
//
//        #expect(throws: ExecutableNameResolverError.emptyPackageSwift) {
//            try ExecutableNameResolver.getExecutableNames(from: directory)
//        }
//    }
//
//    @Test("Throws error when no executables found in Package.swift")
//    func throwsErrorWhenNoExecutablesFound() throws {
//        let packageContent = """
//        // swift-tools-version: 6.0
//        import PackageDescription
//
//        let package = Package(
//            name: "TestPackage",
//            products: [
//                .library(name: "TestLibrary", targets: ["TestTarget"])
//            ],
//            targets: [
//                .target(name: "TestTarget")
//            ]
//        )
//        """
//        let directory = MockDirectory(path: "/test/project")
//        try directory.createFile(named: "Package.swift", contents: packageContent)
//
//        #expect(throws: (any Error).self) {
//            try ExecutableNameResolver.getExecutableNames(from: directory)
//        }
//    }
//
//    @Test("Returns single executable name when one executable found")
//    func returnsSingleExecutableName() throws {
//        let executableName = "TestExecutable"
//        let directory = MockDirectory(path: "/test/project")
//        try createPackageSwift(in: directory, executableName: executableName)
//
//        let names = try ExecutableNameResolver.getExecutableNames(from: directory)
//
//        #expect(names == [executableName])
//    }
//
//    @Test("Returns multiple executable names when multiple executables found")
//    func returnsMultipleExecutableNames() throws {
//        let packageContent = """
//        // swift-tools-version: 6.0
//        import PackageDescription
//
//        let package = Package(
//            name: "TestPackage",
//            products: [
//                .executable(name: "FirstExecutable", targets: ["FirstTarget"]),
//                .executable(name: "SecondExecutable", targets: ["SecondTarget"])
//            ],
//            targets: [
//                .executableTarget(name: "FirstTarget"),
//                .executableTarget(name: "SecondTarget")
//            ]
//        )
//        """
//        let directory = MockDirectory(path: "/test/project")
//        try directory.createFile(named: "Package.swift", contents: packageContent)
//
//        let names = try ExecutableNameResolver.getExecutableNames(from: directory)
//
//        #expect(names.count == 2)
//        #expect(names.contains("FirstExecutable"))
//        #expect(names.contains("SecondExecutable"))
//    }
//
//    @Test("Handles Package.swift with comments and formatting")
//    func handlesPackageSwiftWithCommentsAndFormatting() throws {
//        let packageContent = """
//        // swift-tools-version: 6.0
//        // This is a comment
//        import PackageDescription
//
//        let package = Package(
//            name: "TestPackage",
//            platforms: [
//                .macOS(.v14)
//            ],
//            products: [
//                // Main executable product
//                .executable(
//                    name: "MainApp",
//                    targets: ["MainApp"]
//                ),
//                /* Another executable */
//                .executable(name: "HelperTool", targets: ["HelperTool"])
//            ],
//            dependencies: [
//                // External dependencies
//            ],
//            targets: [
//                .executableTarget(
//                    name: "MainApp",
//                    dependencies: []
//                ),
//                .executableTarget(name: "HelperTool")
//            ]
//        )
//        """
//        let directory = MockDirectory(path: "/test/project")
//        try directory.createFile(named: "Package.swift", contents: packageContent)
//
//        let names = try ExecutableNameResolver.getExecutableNames(from: directory)
//
//        #expect(names.count == 2)
//        #expect(names.contains("MainApp"))
//        #expect(names.contains("HelperTool"))
//    }
//}
//
//
//// MARK: - Private Methods
//private extension ExecutableNameResolverTests {
//    func createPackageSwift(in directory: MockDirectory, executableName: String) throws {
//        let packageContent = """
//        // swift-tools-version: 6.0
//        import PackageDescription
//
//        let package = Package(
//            name: "\(projectName)",
//            platforms: [.macOS(.v14)],
//            products: [
//                .executable(name: "\(executableName)", targets: ["\(executableName)"])
//            ],
//            targets: [
//                .executableTarget(name: "\(executableName)")
//            ]
//        )
//        """
//        try directory.createFile(named: "Package.swift", contents: packageContent)
//    }
//}
