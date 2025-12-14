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
