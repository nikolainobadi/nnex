//
//  VersionNumberControllerTests.swift
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

final class VersionNumberControllerTests {
    @Test("Starting values empty")
    func emptyStartingValues() {
        let (_, gitHandler) = makeSUT()
        
        #expect(gitHandler.message == nil)
    }
}


// MARK: - SUT
private extension VersionNumberControllerTests {
    func makeSUT(
        currentVersion: String? = nil,
        previousVersion: String = "",
        shouldUpdate: Bool = true,
        inputResults: [String] = [],
        grantPermission: Bool = true,
        throwError: Bool = false
    ) -> (sut: VersionNumberController, gitHandler: MockGitHandler) {
        let shell = MockShell()
        let picker = MockSwiftPicker(inputResult: .init(type: .ordered(inputResults)), permissionResult: .init(defaultValue: grantPermission))
        let gitHandler = MockGitHandler(previousVersion: previousVersion)
        let fileSystem = MockFileSystem()
        let service = StubService(throwError: throwError, currentVersion: currentVersion, shouldUpdate: shouldUpdate)
        let sut = VersionNumberController(shell: shell, picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, versionService: service)
        
        return (sut, gitHandler)
    }
    
    func makeVersionInfo(_ type: ReleaseVersionInfo) -> ReleaseVersionInfo {
        return type
    }
}


// MARK: - Mocks
private extension VersionNumberControllerTests {
    final class StubService: @unchecked Sendable, VersionNumberService {
        private let throwError: Bool
        private let currentVersion: String?
        private let shouldUpdate: Bool
        
        init(throwError: Bool, currentVersion: String?, shouldUpdate: Bool) {
            self.throwError = throwError
            self.currentVersion = currentVersion
            self.shouldUpdate = shouldUpdate
        }
        
        func detectArgumentParserVersion(projectPath: String) throws -> String? {
            return currentVersion
        }
        
        func shouldUpdateVersion(currentVersion: String, releaseVersion: String) -> Bool {
            return shouldUpdate
        }
        
        func updateArgumentParserVersion(projectPath: String, newVersion: String) throws -> Bool {
            if throwError { throw NSError(domain: "Test", code: 0) }
            
            return true
        }
    }
}
