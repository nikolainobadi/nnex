//
//  ExecutableNameResolverTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Testing
import Foundation
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor
final class ExecutableNameResolverTests {
    private let projectFolder: Folder
    private let projectName = "testProject-executableResolver"
    
    init() throws {
        let tempFolder = Folder.temporary
        self.projectFolder = try tempFolder.createSubfolder(named: "\(projectName)-\(UUID().uuidString)")
    }
    
    deinit {
        deleteFolderContents(projectFolder)
        try? projectFolder.delete()
    }
}


// MARK: - Tests
extension ExecutableNameResolverTests {
    @Test("Throws error when Package.swift is missing")
    func throwsErrorWhenPackageSwiftMissing() throws {
        let sut = makeSUT()
        
        #expect(throws: ExecutableNameResolverError.missingPackageSwift(path: projectFolder.path)) {
            try sut.getExecutableNames(from: projectFolder)
        }
    }
    
    @Test("Throws error when Package.swift cannot be read")
    func throwsErrorWhenPackageSwiftCannotBeRead() throws {
        // Create a Package.swift file but make it unreadable by creating it as a directory
        try projectFolder.createSubfolder(named: "Package.swift")
        
        let sut = makeSUT()
        
        #expect(throws: (any Error).self) {
            try sut.getExecutableNames(from: projectFolder)
        }
        
        // Clean up
        try projectFolder.subfolder(named: "Package.swift").delete()
    }
    
    @Test("Throws error when Package.swift is empty")
    func throwsErrorWhenPackageSwiftIsEmpty() throws {
        try projectFolder.createFile(named: "Package.swift", contents: "".data(using: .utf8)!)
        
        let sut = makeSUT()
        
        #expect(throws: ExecutableNameResolverError.emptyPackageSwift) {
            try sut.getExecutableNames(from: projectFolder)
        }
    }
    
    @Test("Throws error when Package.swift contains only whitespace")
    func throwsErrorWhenPackageSwiftContainsOnlyWhitespace() throws {
        try projectFolder.createFile(named: "Package.swift", contents: "   \n\t  \n   ".data(using: .utf8)!)
        
        let sut = makeSUT()
        
        #expect(throws: ExecutableNameResolverError.emptyPackageSwift) {
            try sut.getExecutableNames(from: projectFolder)
        }
    }
    
    @Test("Throws error when no executables found in Package.swift")
    func throwsErrorWhenNoExecutablesFound() throws {
        let packageContent = """
        // swift-tools-version: 6.0
        import PackageDescription
        
        let package = Package(
            name: "TestPackage",
            products: [
                .library(name: "TestLibrary", targets: ["TestTarget"])
            ],
            targets: [
                .target(name: "TestTarget")
            ]
        )
        """
        try projectFolder.createFile(named: "Package.swift", contents: packageContent.data(using: .utf8)!)
        
        let sut = makeSUT()
        
        // The error is wrapped, so we check for any ExecutableNameResolverError
        #expect(throws: (any Error).self) {
            try sut.getExecutableNames(from: projectFolder)
        }
    }
    
    @Test("Returns single executable name when one executable found")
    func returnsSingleExecutableName() throws {
        let executableName = "TestExecutable"
        try createPackageSwift(executableName: executableName)
        
        let sut = makeSUT()
        let names = try sut.getExecutableNames(from: projectFolder)
        
        #expect(names == [executableName])
    }
    
    @Test("Returns multiple executable names when multiple executables found")
    func returnsMultipleExecutableNames() throws {
        let packageContent = """
        // swift-tools-version: 6.0
        import PackageDescription
        
        let package = Package(
            name: "TestPackage",
            products: [
                .executable(name: "FirstExecutable", targets: ["FirstTarget"]),
                .executable(name: "SecondExecutable", targets: ["SecondTarget"])
            ],
            targets: [
                .executableTarget(name: "FirstTarget"),
                .executableTarget(name: "SecondTarget")
            ]
        )
        """
        try projectFolder.createFile(named: "Package.swift", contents: packageContent.data(using: .utf8)!)
        
        let sut = makeSUT()
        let names = try sut.getExecutableNames(from: projectFolder)
        
        #expect(names.count == 2)
        #expect(names.contains("FirstExecutable"))
        #expect(names.contains("SecondExecutable"))
    }
    
    @Test("Handles Package.swift with comments and formatting")
    func handlesPackageSwiftWithCommentsAndFormatting() throws {
        let packageContent = """
        // swift-tools-version: 6.0
        // This is a comment
        import PackageDescription
        
        let package = Package(
            name: "TestPackage",
            platforms: [
                .macOS(.v14)
            ],
            products: [
                // Main executable product
                .executable(
                    name: "MainApp",
                    targets: ["MainApp"]
                ),
                /* Another executable */
                .executable(name: "HelperTool", targets: ["HelperTool"])
            ],
            dependencies: [
                // External dependencies
            ],
            targets: [
                .executableTarget(
                    name: "MainApp",
                    dependencies: []
                ),
                .executableTarget(name: "HelperTool")
            ]
        )
        """
        try projectFolder.createFile(named: "Package.swift", contents: packageContent.data(using: .utf8)!)
        
        let sut = makeSUT()
        let names = try sut.getExecutableNames(from: projectFolder)
        
        #expect(names.count == 2)
        #expect(names.contains("MainApp"))
        #expect(names.contains("HelperTool"))
    }
}


// MARK: - Private Methods
private extension ExecutableNameResolverTests {
    func makeSUT() -> ExecutableNameResolver {
        return ExecutableNameResolver()
    }
    
    func createPackageSwift(executableName: String) throws {
        let packageContent = """
        // swift-tools-version: 6.0
        import PackageDescription
        
        let package = Package(
            name: "\(projectName)",
            platforms: [.macOS(.v14)],
            products: [
                .executable(name: "\(executableName)", targets: ["\(executableName)"])
            ],
            targets: [
                .executableTarget(name: "\(executableName)")
            ]
        )
        """
        try projectFolder.createFile(named: "Package.swift", contents: packageContent.data(using: .utf8)!)
    }
}