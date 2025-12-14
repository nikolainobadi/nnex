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
