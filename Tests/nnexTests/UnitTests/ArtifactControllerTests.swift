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


// MARK: - SUT
private extension ArtifactControllerTests {
    func makeSUT(shellResults: [String] = [], previousVersion: String = "", tapsToLoad: [HomebrewTap]? = [], buildResultToLoad: BuildResult? = nil) -> (sut: ArtifactController, delegate: MockDelegate) {
        let shell = MockShell(results: shellResults)
        let picker = MockSwiftPicker(selectionResult: .init(defaultSingle: .index(0)))
        let gitHandler = MockGitHandler(previousVersion: previousVersion)
        let fileSystem = MockFileSystem()
        let delegate = MockDelegate(tapsToLoad: tapsToLoad, buildResult: buildResultToLoad)
        let sut = ArtifactController(shell: shell, picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, delegate: delegate)
        
        return (sut, delegate)
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
        
        func updateArgumentParserVersion(projectPath: String, newVersion: String) throws -> Bool {
            return false // TODO: -
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
