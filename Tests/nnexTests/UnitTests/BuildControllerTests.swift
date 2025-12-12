//
//  BuildControllerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/31/25.
//

import NnexKit
import Testing
import Foundation
import NnShellTesting
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex

final class BuildControllerTests {
    @Test("Starting values empty")
    func startingValuesEmpty() {
        let (_, service, _) = makeSUT()
        
        #expect(service.capturedConfig == nil)
        #expect(service.capturedOutputLocation == nil)
    }
    
    @Test("Builds executable with provided path and defaults")
    func buildExecutableWithProvidedPath() throws {
        let project = try makeProjectDirectory(path: "/project/", executableNames: ["App"])
        let (sut, service, _) = makeSUT(projectDirectory: project, selectedIndex: 0)
        
        try sut.buildExecutable(path: project.path, buildType: .universal, clean: true, openInFinder: false)
        
        let config = try #require(service.capturedConfig)
        let outputLocation = try #require(service.capturedOutputLocation)
        
        #expect(config.projectName == "App")
        #expect(config.projectPath == project.path)
        #expect(config.buildType == .universal)
        #expect(config.skipClean == false) // clean flag true => skipClean false
        #expect(config.extraBuildArgs.isEmpty)
        #expect(config.testCommand == nil)
        
        switch outputLocation {
        case .currentDirectory:
            break
        default:
            Issue.record("Unexpected output location")
        }
    }
    
    @Test("Prompts when multiple executables and uses selected name")
    func buildExecutableWithMultipleNames() throws {
        let project = try makeProjectDirectory(path: "/project", executableNames: ["App", "Helper"])
        // Single selection index will be used for both executable and output location prompts.
        let (sut, service, _) = makeSUT(projectDirectory: project, selectedIndex: 1)
        
        try sut.buildExecutable(path: project.path, buildType: .arm64, clean: false, openInFinder: false)
        
        let config = try #require(service.capturedConfig)
        let outputLocation = try #require(service.capturedOutputLocation)
        
        #expect(config.projectName == "Helper")
        #expect(config.buildType == .arm64)
        #expect(config.skipClean == true) // clean flag false => skipClean true
        
        switch outputLocation {
        case .desktop:
            break
        default:
            Issue.record("Unexpected output location")
        }
    }
    
    @Test("Uses custom output location after confirmation")
    func buildExecutableWithCustomOutputLocation() throws {
        let project = try makeProjectDirectory(path: "/project", executableNames: ["App"])
        let customDir = MockDirectory(path: "/custom/output")
        let (sut, service, _) = makeSUT(
            projectDirectory: project,
            selectedIndex: 2, // choose custom output
            permissionResponses: [true],
            browsedDirectory: customDir
        )
        
        try sut.buildExecutable(path: project.path, buildType: .x86_64, clean: true, openInFinder: false)
        
        let outputLocation = try #require(service.capturedOutputLocation)
        
        switch outputLocation {
        case .custom(let path):
            #expect(path == customDir.path)
        default:
            Issue.record("Unexpected output location")
        }
    }
    
    @Test("Opens Finder when requested for single build")
    func buildExecutableOpensFinderOnSuccess() throws {
        let project = try makeProjectDirectory(path: "/project", executableNames: ["App"])
        let binaryPath = "/project/.build/arm64-apple-macosx/release/App"
        let shell = MockShell()
        let result = BuildResult(executableName: "App", binaryOutput: .single(binaryPath))
        let (sut, service, _) = makeSUT(
            projectDirectory: project,
            selectedIndex: 0,
            shell: shell,
            resultToReturn: result
        )
        
        try sut.buildExecutable(path: project.path, buildType: .arm64, clean: true, openInFinder: true)
        
        #expect(shell.executedCommands.contains { $0.contains("open -R \(binaryPath)") })
        #expect(service.capturedConfig?.projectName == "App")
    }
    
    @Test("Propagates build service errors")
    func buildExecutablePropagatesErrors() {
        let project = try! makeProjectDirectory(path: "/project", executableNames: ["App"])
        let (sut, service, _) = makeSUT(projectDirectory: project, selectedIndex: 0, throwServiceError: true)
        
        #expect(throws: (any Error).self) {
            try sut.buildExecutable(path: project.path, buildType: .universal, clean: true, openInFinder: false)
        }
        
        #expect(service.capturedConfig == nil)
    }
}


// MARK: - SUT
private extension BuildControllerTests {
    func makeSUT(
        projectDirectory: MockDirectory? = nil,
        selectedIndex: Int = 0,
        permissionResponses: [Bool] = [],
        browsedDirectory: MockDirectory? = nil,
        shell: MockShell = MockShell(),
        resultToReturn: BuildResult = .init(executableName: "App", binaryOutput: .single("/tmp/App")),
        throwServiceError: Bool = false
    ) -> (sut: BuildController, service: MockBuildService, projectDirectory: MockDirectory) {
        let projectDirectory = projectDirectory ?? MockDirectory(path: "/project")
        let picker = MockSwiftPicker(
            inputResult: .init(type: .ordered([])),
            permissionResult: .init(type: .ordered(permissionResponses)),
            selectionResult: .init(defaultSingle: .index(selectedIndex))
        )
        let fileSystem = MockFileSystem(currentDirectory: projectDirectory, directoryMap: [projectDirectory.path: projectDirectory])
        let folderBrowser = MockDirectoryBrowser(filePathToReturn: nil, directoryToReturn: browsedDirectory)
        let service = MockBuildService(resultToReturn: resultToReturn, throwError: throwServiceError)
        let sut = BuildController(shell: shell, picker: picker, fileSystem: fileSystem, buildService: service, folderBrowser: folderBrowser)
        
        return (sut, service, projectDirectory)
    }
    
    func makeProjectDirectory(path: String, executableNames: [String]) throws -> MockDirectory {
        let directory = MockDirectory(path: path)
        let products = executableNames
            .map { """
                .executable(name: "\($0)", targets: ["\($0)"])
            """ }
            .joined(separator: ",")
        
        let targets = executableNames
            .map { """
                .executableTarget(name: "\($0)")
            """ }
            .joined(separator: ",")
        
        let packageContent = """
        // swift-tools-version: 6.0
        import PackageDescription

        let package = Package(
            name: "TestPackage",
            platforms: [.macOS(.v14)],
            products: [
                \(products)
            ],
            targets: [
                \(targets)
            ]
        )
        """
        
        try directory.createFile(named: "Package.swift", contents: packageContent)
        
        return directory
    }
}


// MARK: - Mocks
private extension BuildControllerTests {
    final class MockBuildService: BuildService {
        private let resultToReturn: BuildResult
        private let throwError: Bool
        
        private(set) var capturedConfig: BuildConfig?
        private(set) var capturedOutputLocation: BuildOutputLocation?
        
        init(resultToReturn: BuildResult, throwError: Bool) {
            self.resultToReturn = resultToReturn
            self.throwError = throwError
        }
        
        func buildExecutable(config: BuildConfig, outputLocation: BuildOutputLocation) throws -> BuildResult {
            if throwError { throw NSError(domain: "Test", code: 0) }
            capturedConfig = config
            capturedOutputLocation = outputLocation
            return resultToReturn
        }
    }
}
