//  BuildManagerTests.swift
//  NnexKitTests
//
//  Created by Nikolai Nobadi on 3/31/25.
//

import Testing
import NnShellTesting
import NnexSharedTestHelpers
@testable import NnexKit

struct BuildManagerTests {
    private let projectName = "TestExecutable"
    private let projectPath = "/path/to/project"
}


// MARK: - Tests
extension BuildManagerTests {
    @Test("Returns original result when output is current directory")
    func returnsCurrentDirectoryResult() throws {
        let (sut, shell) = makeSUT(results: ["", ""])
        let config = makeConfig(buildType: .arm64, skipClean: true)
        let result = try sut.buildExecutable(config: config, outputLocation: .currentDirectory(.arm64))
        
        switch result.binaryOutput {
        case .single(let path):
            #expect(path.contains(projectPath))
            #expect(path.contains(projectName))
            #expect(path.contains("arm64-apple-macosx"))
        default:
            Issue.record("Unexpected binary output")
        }
        
        #expect(!shell.executedCommand(containing: "cp"))
    }
    
    @Test("Copies single binary to desktop")
    func copiesSingleBinaryToDesktop() throws {
        let desktop = MockDirectory(path: "/Users/Home/Desktop")
        let (sut, shell) = makeSUT(results: ["", "", ""], desktop: desktop)
        let config = makeConfig(buildType: .arm64, skipClean: true)
        let result = try sut.buildExecutable(config: config, outputLocation: .desktop)
        
        switch result.binaryOutput {
        case .single(let path):
            #expect(path == "\(desktop.path)/\(projectName)")
        default:
            Issue.record("Unexpected binary output")
        }
        
        #expect(shell.executedCommand(containing: "cp"))
        #expect(shell.executedCommand(containing: desktop.path))
    }
    
    @Test("Copies universal binaries to custom location with arch suffixes")
    func copiesUniversalBinaryToCustomLocation() throws {
        let (sut, shell) = makeSUT(results: ["", "", "", "", "", ""])
        let destination = "/custom/output"
        let config = makeConfig(buildType: .universal, skipClean: true)
        let result = try sut.buildExecutable(config: config, outputLocation: .custom(destination))
        
        switch result.binaryOutput {
        case .multiple(let binaries):
            let armPath = binaries[.arm]
            let intelPath = binaries[.intel]
            
            #expect(armPath == "\(destination)/\(projectName)-arm64")
            #expect(intelPath == "\(destination)/\(projectName)-x86_64")
        default:
            Issue.record("Unexpected binary output")
        }
        
        #expect(shell.executedCommand(containing: "cp"))
        #expect(shell.executedCommand(containing: "\(projectName)-arm64"))
        #expect(shell.executedCommand(containing: "\(projectName)-x86_64"))
    }
}


// MARK: - Helpers
private extension BuildManagerTests {
    func makeSUT(results: [String] = [], desktop: MockDirectory? = nil) -> (sut: BuildManager, shell: MockShell) {
        let shell = MockShell(results: results)
        let fileSystem = MockFileSystem(desktop: desktop)
        let sut = BuildManager(shell: shell, fileSystem: fileSystem)
        
        return (sut, shell)
    }
    
    func makeConfig(buildType: BuildType, skipClean: Bool) -> BuildConfig {
        .init(
            projectName: projectName,
            projectPath: projectPath,
            buildType: buildType,
            extraBuildArgs: [],
            skipClean: skipClean,
            testCommand: nil
        )
    }
}
