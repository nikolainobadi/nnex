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
    @Test("Starting values empty")
    func startingValuesEmpty() {
        let (_, delegate) = makeSUT()

        #expect(delegate.buildData == nil)
    }
}


// MARK: - Build Artifacts
extension ArtifactControllerTests {
    @Test("Builds artifacts with single binary")
    func buildsArtifactsWithSingleBinary() throws {
        let expectedVersion = "1.5.0"
        let expectedExecutableName = "myapp"
        let buildResult = makeBuildResult(executableName: expectedExecutableName, binaryOutput: .single("/path/to/myapp"))
        let shellResults = ["", "abc123def456"]  // tar result (consumed), shasum result
        let sut = makeSUT(shellResults: shellResults, buildResultToLoad: buildResult).sut
        let folder = MockDirectory(path: "/test/test-project")

        let artifact = try sut.buildArtifacts(projectFolder: folder, buildType: .universal, versionNumber: expectedVersion)

        #expect(artifact.version == expectedVersion)
        #expect(artifact.executableName == expectedExecutableName)
        #expect(artifact.archives.count == 1)
        #expect(artifact.archives[0].sha256 == "abc123def456")
    }

    @Test("Builds artifacts with multiple binaries")
    func buildsArtifactsWithMultipleBinaries() throws {
        let expectedVersion = "2.0.0"
        let binaries: [ReleaseArchitecture: String] = [
            .arm: "/path/.build/arm64-apple-macosx/release/app",
            .intel: "/path/.build/x86_64-apple-macosx/release/app"
        ]
        let buildResult = makeBuildResult(executableName: "app", binaryOutput: .multiple(binaries))
        let shellResults = ["", "sha1", "", "sha2"]  // tar, shasum, tar, shasum
        let (sut, delegate) = makeSUT(shellResults: shellResults, buildResultToLoad: buildResult)
        let folder = MockDirectory(path: "/test/multi-arch")

        let artifact = try sut.buildArtifacts(projectFolder: folder, buildType: .universal, versionNumber: expectedVersion)

        #expect(artifact.version == expectedVersion)
        #expect(artifact.archives.count == 2)
        #expect(delegate.buildData != nil)
    }
}


// MARK: - Formula Integration
extension ArtifactControllerTests {
    @Test("Uses extra build args from existing formula")
    func usesExtraBuildArgsFromFormula() throws {
        let expectedArgs = ["--flag1", "--flag2"]
        let formula = makeFormula(name: "test-project", extraBuildArgs: expectedArgs)
        let tap = makeHomebrewTap(formulas: [formula])
        let buildResult = makeBuildResult(executableName: "app", binaryOutput: .single("/path/app"))
        let shellResults = ["", "sha256"]
        let (sut, delegate) = makeSUT(shellResults: shellResults, tapsToLoad: [tap], buildResultToLoad: buildResult)
        let folder = MockDirectory(path: "/test/test-project")

        _ = try sut.buildArtifacts(projectFolder: folder, buildType: .universal, versionNumber: "1.0.0")

        let buildData = try #require(delegate.buildData)
        #expect(buildData.extraArs == expectedArgs)
    }

    @Test("Uses test command from existing formula")
    func usesTestCommandFromFormula() throws {
        let expectedTestCommand = HomebrewFormula.TestCommand.custom("make test")
        let formula = makeFormula(name: "test-app", testCommand: expectedTestCommand)
        let tap = makeHomebrewTap(formulas: [formula])
        let buildResult = makeBuildResult(executableName: "app", binaryOutput: .single("/path/app"))
        let shellResults = ["", "sha256"]
        let (sut, delegate) = makeSUT(shellResults: shellResults, tapsToLoad: [tap], buildResultToLoad: buildResult)
        let folder = MockDirectory(path: "/test/test-app")

        _ = try sut.buildArtifacts(projectFolder: folder, buildType: .universal, versionNumber: "1.0.0")

        let buildData = try #require(delegate.buildData)
        #expect(buildData.testCommand != nil)
    }

    @Test("Uses empty build args when no formula exists")
    func usesEmptyBuildArgsWithoutFormula() throws {
        let buildResult = makeBuildResult(executableName: "app", binaryOutput: .single("/path/app"))
        let shellResults = ["", "sha256"]
        let (sut, delegate) = makeSUT(shellResults: shellResults, tapsToLoad: [], buildResultToLoad: buildResult)
        let folder = MockDirectory(path: "/test/unknown-project")

        _ = try sut.buildArtifacts(projectFolder: folder, buildType: .universal, versionNumber: "1.0.0")

        let buildData = try #require(delegate.buildData)
        #expect(buildData.extraArs.isEmpty)
        #expect(buildData.testCommand == nil)
    }
}


// MARK: - SUT
private extension ArtifactControllerTests {
    func makeSUT(shellResults: [String] = [], tapsToLoad: [HomebrewTap]? = [], buildResultToLoad: BuildResult? = nil) -> (sut: ArtifactController, delegate: MockDelegate) {
        let shell = MockShell(results: shellResults)
        let picker = MockSwiftPicker(selectionResult: .init(defaultSingle: .index(0)))
        let fileSystem = MockFileSystem()
        let delegate = MockDelegate(tapsToLoad: tapsToLoad, buildResult: buildResultToLoad)
        let sut = ArtifactController(shell: shell, picker: picker, fileSystem: fileSystem, delegate: delegate)
        
        return (sut, delegate)
    }
}


// MARK: - Mocks
private extension ArtifactControllerTests {
    final class MockDelegate: ArtifactDelegate {
        private let tapsToLoad: [HomebrewTap]?
        private let buildResult: BuildResult?

        private(set) var buildData: (folder: any Directory, buildType: BuildType, extraArs: [String], testCommand: HomebrewFormula.TestCommand?)?

        init(tapsToLoad: [HomebrewTap]?, buildResult: BuildResult?) {
            self.tapsToLoad = tapsToLoad
            self.buildResult = buildResult
        }

        func loadTaps() throws -> [HomebrewTap] {
            guard let tapsToLoad else {
                throw NSError(domain: "Test", code: 0)
            }

            return tapsToLoad
        }

        func buildExecutable(projectFolder: any Directory, buildType: BuildType, extraBuildArgs: [String], testCommand: HomebrewFormula.TestCommand?) throws -> BuildResult {
            guard let buildResult else {
                throw NSError(domain: "Test", code: 0)
            }

            buildData = (projectFolder, buildType, extraBuildArgs, testCommand)

            return buildResult
        }
    }
}


// MARK: - Test Helpers
private extension ArtifactControllerTests {
    func makeBuildResult(executableName: String, binaryOutput: BinaryOutput) -> BuildResult {
        return .init(executableName: executableName, binaryOutput: binaryOutput)
    }

    func makeHomebrewTap(name: String = "test-tap", formulas: [HomebrewFormula] = []) -> HomebrewTap {
        return .init(name: name, localPath: "/local/tap", remotePath: "https://github.com/user/tap", formulas: formulas)
    }

    func makeFormula(name: String, extraBuildArgs: [String] = [], testCommand: HomebrewFormula.TestCommand? = nil) -> HomebrewFormula {
        return .init(
            name: name,
            details: "Test formula",
            homepage: "https://example.com",
            license: "MIT",
            localProjectPath: "/local/project",
            uploadType: .binary,
            testCommand: testCommand,
            extraBuildArgs: extraBuildArgs
        )
    }
}
