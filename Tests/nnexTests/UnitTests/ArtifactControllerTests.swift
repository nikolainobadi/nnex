//
//  ArtifactControllerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit
import Testing
import Foundation
import NnShellTesting
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex

final class ArtifactControllerTests {
    @Test("Uses existing formula configuration when building artifacts")
    func buildArtifactsUsesFormulaArgs() throws {
        let project = MockDirectory(path: "/project/App")
        let binaryPath = "/project/.build/arm64-apple-macosx/release/App"
        let buildResult = BuildResult(executableName: "App", binaryOutput: .single(binaryPath))
        let formula = HomebrewFormula(
            name: "app",
            details: "",
            homepage: "",
            license: "",
            localProjectPath: project.path,
            uploadType: .binary,
            testCommand: .custom("swift test"),
            extraBuildArgs: ["--flag"]
        )
        let tap = HomebrewTap(name: "Tap", localPath: "", remotePath: "", formulas: [formula])
        let commandResults = makeCommandResults(for: [binaryPath], shaPrefix: "hash")
        let shell = makeShell(commandResults: commandResults)
        let (sut, delegate, gitHandler, _, _, _) = makeSUT(
            projectFolder: project,
            buildResult: buildResult,
            taps: [tap],
            shell: shell
        )
        
        let artifact = try sut.buildArtifacts(projectFolder: project, buildType: .arm64, versionInfo: .version("2.0.0"))
        
        #expect(delegate.capturedBuildType == .arm64)
        #expect(delegate.capturedExtraBuildArgs == ["--flag"])
        if case .custom(let command) = delegate.capturedTestCommand {
            #expect(command == "swift test")
        } else {
            Issue.record("Expected custom test command")
        }
        #expect(artifact.version == "2.0.0")
        #expect(artifact.executableName == "App")
        
        let archive = try #require(artifact.archives.first)
        #expect(archive.sha256 == "hash0")
        #expect(archive.archivePath.hasSuffix("App-arm64.tar.gz"))
        #expect(gitHandler.message == nil)
    }
    
    @Test("Increments previous version when user requests it")
    func buildArtifactsIncrementsVersion() throws {
        let project = MockDirectory(path: "/project/App")
        let binaryPath = "/project/.build/arm64-apple-macosx/release/App"
        let buildResult = BuildResult(executableName: "App", binaryOutput: .single(binaryPath))
        let shell = makeShell(commandResults: makeCommandResults(for: [binaryPath], shaPrefix: "sha"))
        let picker = ArtifactControllerTests.makePicker(inputResults: ["minor"])
        let gitHandler = MockGitHandler(previousVersion: "1.2.3")
        let (sut, delegate, _, _, _, _) = makeSUT(
            projectFolder: project,
            buildResult: buildResult,
            gitHandler: gitHandler,
            shell: shell,
            picker: picker
        )
        
        let artifact = try sut.buildArtifacts(projectFolder: project, buildType: .universal, versionInfo: nil)
        
        #expect(artifact.version == "1.3.0")
        #expect(delegate.capturedBuildType == .universal)
    }
    
    @Test("Archives multiple binaries by architecture")
    func buildArtifactsArchivesMultipleBinaries() throws {
        let project = MockDirectory(path: "/project/App")
        let armPath = "/project/.build/arm64-apple-macosx/release/App"
        let intelPath = "/project/.build/x86_64-apple-macosx/release/App"
        let buildResult = BuildResult(executableName: "App", binaryOutput: .multiple([.arm: armPath, .intel: intelPath]))
        let commandResults = makeCommandResults(for: [armPath, intelPath], shaPrefix: "sha")
        let shell = makeShell(commandResults: commandResults)
        let (sut, _, _, shellRef, _, _) = makeSUT(
            projectFolder: project,
            buildResult: buildResult,
            shell: shell
        )
        
        let artifact = try sut.buildArtifacts(projectFolder: project, buildType: .arm64, versionInfo: .version("0.1.0"))
        
        #expect(artifact.archives.count == 2)
        #expect(artifact.archives[0].archivePath.contains("arm64"))
        #expect(artifact.archives[1].archivePath.contains("x86_64"))
        #expect(shellRef.executedCommands.count == 4)
    }
    
    @Test("Updates source version and commits when permission granted")
    func buildArtifactsPerformsAutoVersionUpdate() throws {
        let project = MockDirectory(path: "/project")
        let binaryPath = "/project/.build/arm64-apple-macosx/release/App"
        let buildResult = BuildResult(executableName: "App", binaryOutput: .single(binaryPath))
        let mainContent = """
        import ArgumentParser
        @main
        struct App: ParsableCommand {
            static let configuration = CommandConfiguration(version: "1.0.0")
        }
        """
        let sourcesDirectory = MockDirectory(path: "/project/Sources", containedFiles: ["Main.swift"])
        try sourcesDirectory.createFile(named: "Main.swift", contents: mainContent)
        let fileSystem = MockFileSystem(directoryMap: [sourcesDirectory.path: sourcesDirectory])
        let shell = makeShell(commandResults: makeCommandResults(for: [binaryPath], shaPrefix: "sha"))
        let picker = ArtifactControllerTests.makePicker(permissionResults: [true])
        let gitHandler = MockGitHandler(previousVersion: "1.0.0")
        let (sut, _, git, _, fs, _) = makeSUT(
            projectFolder: project,
            buildResult: buildResult,
            gitHandler: gitHandler,
            shell: shell,
            picker: picker,
            fileSystem: fileSystem
        )
        
        let artifact = try sut.buildArtifacts(projectFolder: project, buildType: .arm64, versionInfo: .version("v1.1.0"))
        
        #expect(artifact.version == "v1.1.0")
        #expect(git.message == "Update version to v1.1.0")
        let updatedContent = try fs.readFile(at: sourcesDirectory.path.appendingPathComponent("Main.swift"))
        #expect(updatedContent.contains("version: \"1.1.0\""))
    }
}


// MARK: - SUT
private extension ArtifactControllerTests {
    func makeSUT(projectFolder: MockDirectory, buildResult: BuildResult, taps: [HomebrewTap] = [], gitHandler: MockGitHandler = MockGitHandler(), shell: MockShell, picker: MockSwiftPicker = ArtifactControllerTests.makePicker(), fileSystem: MockFileSystem = MockFileSystem()) -> (sut: ArtifactController, delegate: MockArtifactDelegate, gitHandler: MockGitHandler, shell: MockShell, fileSystem: MockFileSystem, picker: MockSwiftPicker) {
        let delegate = MockArtifactDelegate(taps: taps, buildResult: buildResult)
        let sut = ArtifactController(shell: shell, picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, delegate: delegate)
        
        return (sut, delegate, gitHandler, shell, fileSystem, picker)
    }
    
    func makeShell(commandResults: [String: String]) -> MockShell {
        let commands = commandResults.map { MockCommand(command: $0.key, output: $0.value) }
        return MockShell(commands: commands)
    }
    
    func makeCommandResults(for binaryPaths: [String], shaPrefix: String) -> [String: String] {
        var results: [String: String] = [:]
        
        for (index, path) in binaryPaths.enumerated() {
            let url = URL(fileURLWithPath: path)
            let fileName = url.lastPathComponent
            let directory = url.deletingLastPathComponent().path
            
            let archiveName: String
            if path.contains("arm64-apple-macosx") {
                archiveName = "\(fileName)-arm64.tar.gz"
            } else if path.contains("x86_64-apple-macosx") {
                archiveName = "\(fileName)-x86_64.tar.gz"
            } else {
                archiveName = "\(fileName).tar.gz"
            }
            
            let tarCommand = "cd \"\(directory)\" && tar -czf \"\(archiveName)\" \"\(fileName)\""
            let shaCommand = "shasum -a 256 \"\(directory)/\(archiveName)\""
            results[tarCommand] = ""
            results[shaCommand] = "\(shaPrefix)\(index)"
        }
        
        return results
    }
}


// MARK: - Mocks
private extension ArtifactControllerTests {
    final class MockArtifactDelegate: ArtifactDelegate {
        private let taps: [HomebrewTap]
        private let buildResult: BuildResult
        private let shouldThrow: Bool
        
        private(set) var capturedProjectFolder: (any Directory)?
        private(set) var capturedBuildType: BuildType?
        private(set) var capturedExtraBuildArgs: [String]?
        private(set) var capturedTestCommand: HomebrewFormula.TestCommand?
        
        init(taps: [HomebrewTap], buildResult: BuildResult, shouldThrow: Bool = false) {
            self.taps = taps
            self.buildResult = buildResult
            self.shouldThrow = shouldThrow
        }
        
        func loadTaps() throws -> [HomebrewTap] {
            if shouldThrow { throw NSError(domain: "Test", code: 0) }
            return taps
        }
        
        func buildExecutable(projectFolder: any Directory, buildType: BuildType, extraBuildArgs: [String], testCommand: HomebrewFormula.TestCommand?) throws -> BuildResult {
            if shouldThrow { throw NSError(domain: "Test", code: 0) }
            capturedProjectFolder = projectFolder
            capturedBuildType = buildType
            capturedExtraBuildArgs = extraBuildArgs
            capturedTestCommand = testCommand
            return buildResult
        }
    }
    
    static func makePicker(inputResults: [String] = [], permissionResults: [Bool] = []) -> MockSwiftPicker {
        MockSwiftPicker(
            inputResult: .init(type: .ordered(inputResults)),
            permissionResult: .init(type: .ordered(permissionResults)),
            selectionResult: .init(defaultSingle: .index(0))
        )
    }
}
