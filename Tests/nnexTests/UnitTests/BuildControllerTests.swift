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

        #expect(service.buildData == nil)
    }
}


// MARK: - Build Executable (User Command)
extension BuildControllerTests {
    @Test("Builds executable with single executable in package")
    func buildsExecutableWithSingleExecutable() throws {
        let projectDirectory = try makeProjectDirectory(path: "/project/myapp", executableNames: ["myapp"])
        let (sut, service, _) = makeSUT(projectDirectory: projectDirectory)

        try sut.buildExecutable(path: nil, buildType: .universal, clean: true, openInFinder: false)

        let buildData = try #require(service.buildData)
        #expect(buildData.config.projectName == "myapp")
        #expect(buildData.config.buildType == .universal)
        #expect(buildData.config.skipClean == false)
    }

    @Test("Builds executable with multiple executables using picker")
    func buildsExecutableWithMultipleExecutables() throws {
        let projectDirectory = try makeProjectDirectory(path: "/project", executableNames: ["app1", "app2", "app3"])
        let (sut, service, _) = makeSUT(projectDirectory: projectDirectory, selectedIndex: 1)

        try sut.buildExecutable(path: nil, buildType: .arm64, clean: false, openInFinder: false)

        let buildData = try #require(service.buildData)
        #expect(buildData.config.projectName == "app2")
        #expect(buildData.config.buildType == .arm64)
        #expect(buildData.config.skipClean == true)
    }

    @Test("Selects current directory as output location")
    func selectsCurrentDirectoryAsOutput() throws {
        let projectDirectory = try makeProjectDirectory(path: "/project/app", executableNames: ["app"])
        let (sut, service, _) = makeSUT(projectDirectory: projectDirectory, selectedIndex: 0)

        try sut.buildExecutable(path: nil, buildType: .x86_64, clean: true, openInFinder: false)

        let buildData = try #require(service.buildData)
        if case .currentDirectory(let buildType) = buildData.outputLocation {
            #expect(buildType == .x86_64)
        } else {
            Issue.record("Expected currentDirectory output location")
        }
    }

    @Test("Selects desktop as output location")
    func selectsDesktopAsOutput() throws {
        let projectDirectory = try makeProjectDirectory(path: "/project/app", executableNames: ["app"])
        let (sut, service, _) = makeSUT(projectDirectory: projectDirectory, selectedIndex: 1)

        try sut.buildExecutable(path: nil, buildType: .universal, clean: true, openInFinder: false)

        let buildData = try #require(service.buildData)
        if case .desktop = buildData.outputLocation {
            // Success
        } else {
            Issue.record("Expected desktop output location")
        }
    }

    @Test("Handles custom output location with folder browser", .disabled()) // TODO: - 
    func handlesCustomOutputLocation() throws {
        let projectDirectory = try makeProjectDirectory(path: "/project/app", executableNames: ["app"])
        let customFolder = MockDirectory(path: "/custom/location")
        let (sut, service, _) = makeSUT(projectDirectory: projectDirectory, selectedIndex: 2, permissionResponses: [true], browsedDirectory: customFolder)

        try sut.buildExecutable(path: nil, buildType: .universal, clean: true, openInFinder: false)

        let buildData = try #require(service.buildData)
        if case .custom(let path) = buildData.outputLocation {
            #expect(path == "/custom/location")
        } else {
            Issue.record("Expected custom output location")
        }
    }
}


// MARK: - Build Executable (Publish Integration)
extension BuildControllerTests {
    @Test("Builds with extra build args and test command")
    func buildsWithExtraArgsAndTestCommand() throws {
        let projectDirectory = try makeProjectDirectory(path: "/project/app", executableNames: ["app"])
        let expectedArgs = ["--flag1", "--flag2"]
        let expectedTestCommand = HomebrewFormula.TestCommand.custom("make test")
        let (sut, service, _) = makeSUT(projectDirectory: projectDirectory)

        _ = try sut.buildExecutable(projectFolder: projectDirectory, buildType: .universal, clean: true, outputLocation: nil, extraBuildArgs: expectedArgs, testCommand: expectedTestCommand)

        let buildData = try #require(service.buildData)
        #expect(buildData.config.extraBuildArgs == expectedArgs)
        #expect(buildData.config.testCommand != nil)
    }

    @Test("Builds with empty extra args when none provided")
    func buildsWithEmptyExtraArgs() throws {
        let projectDirectory = try makeProjectDirectory(path: "/project/app", executableNames: ["app"])
        let (sut, service, _) = makeSUT(projectDirectory: projectDirectory)

        _ = try sut.buildExecutable(projectFolder: projectDirectory, buildType: .arm64, clean: false, outputLocation: nil, extraBuildArgs: [], testCommand: nil)

        let buildData = try #require(service.buildData)
        #expect(buildData.config.extraBuildArgs.isEmpty)
        #expect(buildData.config.testCommand == nil)
    }

    @Test("Creates config with correct project path")
    func createsConfigWithCorrectProjectPath() throws {
        let projectPath = "/project/myapp"
        let projectDirectory = try makeProjectDirectory(path: projectPath, executableNames: ["myapp"])
        let (sut, service, _) = makeSUT(projectDirectory: projectDirectory)

        _ = try sut.buildExecutable(projectFolder: projectDirectory, buildType: .universal, clean: true, outputLocation: nil, extraBuildArgs: [], testCommand: nil)

        let buildData = try #require(service.buildData)
        #expect(buildData.config.projectPath.contains(projectPath))
    }
}


// MARK: - SUT
private extension BuildControllerTests {
    func makeSUT(
        shell: MockShell? = nil,
        projectDirectory: MockDirectory? = nil,
        selectedIndex: Int = 0,
        permissionResponses: [Bool] = [],
        browsedDirectory: MockDirectory? = nil,
        resultToReturn: BuildResult = .init(executableName: "App", binaryOutput: .single("/tmp/App")),
        throwServiceError: Bool = false
    ) -> (sut: BuildController, service: MockBuildService, projectDirectory: MockDirectory) {
        let shell = shell ?? MockShell()
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
        
        private(set) var buildData: (config: BuildConfig, outputLocation: BuildOutputLocation)?
        
        init(resultToReturn: BuildResult, throwError: Bool) {
            self.resultToReturn = resultToReturn
            self.throwError = throwError
        }
        
        func buildExecutable(config: BuildConfig, outputLocation: BuildOutputLocation) throws -> BuildResult {
            if throwError { throw NSError(domain: "Test", code: 0) }
            
            buildData = (config, outputLocation)
            
            return resultToReturn
        }
    }
}
