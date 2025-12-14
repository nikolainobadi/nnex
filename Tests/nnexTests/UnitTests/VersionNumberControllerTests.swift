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


// MARK: - Select Version with Provided Info
extension VersionNumberControllerTests {
    @Test("Selects version when version info provided")
    func selectsVersionWithProvidedInfo() throws {
        let expectedVersion = "2.5.0"
        let versionInfo = makeVersionInfo(.version(expectedVersion))
        let (sut, _) = makeSUT()

        let version = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: versionInfo)

        #expect(version == expectedVersion)
    }

    @Test("Increments major version when provided")
    func incrementsMajorVersion() throws {
        let previousVersion = "1.2.3"
        let versionInfo = makeVersionInfo(.increment(.major))
        let (sut, _) = makeSUT(previousVersion: previousVersion)

        let version = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: versionInfo)

        #expect(version == "2.0.0")
    }

    @Test("Increments minor version when provided")
    func incrementsMinorVersion() throws {
        let previousVersion = "1.2.3"
        let versionInfo = makeVersionInfo(.increment(.minor))
        let (sut, _) = makeSUT(previousVersion: previousVersion)

        let version = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: versionInfo)

        #expect(version == "1.3.0")
    }

    @Test("Increments patch version when provided")
    func incrementsPatchVersion() throws {
        let previousVersion = "1.2.3"
        let versionInfo = makeVersionInfo(.increment(.patch))
        let (sut, _) = makeSUT(previousVersion: previousVersion)

        let version = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: versionInfo)

        #expect(version == "1.2.4")
    }
}


// MARK: - Select Version with Interactive Input
extension VersionNumberControllerTests {
    @Test("Selects version from user input")
    func selectsVersionFromInput() throws {
        let expectedVersion = "3.0.0"
        let (sut, _) = makeSUT(inputResults: [expectedVersion])

        let version = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: nil)

        #expect(version == expectedVersion)
    }

    @Test("Increments major from user input")
    func incrementsMajorFromInput() throws {
        let previousVersion = "1.5.2"
        let (sut, _) = makeSUT(previousVersion: previousVersion, inputResults: ["major"])

        let version = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: nil)

        #expect(version == "2.0.0")
    }

    @Test("Increments minor from user input")
    func incrementsMinorFromInput() throws {
        let previousVersion = "2.3.1"
        let (sut, _) = makeSUT(previousVersion: previousVersion, inputResults: ["minor"])

        let version = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: nil)

        #expect(version == "2.4.0")
    }

    @Test("Increments patch from user input")
    func incrementsPatchFromInput() throws {
        let previousVersion = "1.0.0"
        let (sut, _) = makeSUT(previousVersion: previousVersion, inputResults: ["patch"])

        let version = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: nil)

        #expect(version == "1.0.1")
    }
}


// MARK: - Auto Version Update
extension VersionNumberControllerTests {
    @Test("Updates version in source when user grants permission")
    func updatesVersionWithPermission() throws {
        let currentVersion = "1.0.0"
        let releaseVersion = "2.0.0"
        let versionInfo = makeVersionInfo(.version(releaseVersion))
        let (sut, gitHandler) = makeSUT(currentVersion: currentVersion, shouldUpdate: true, grantPermission: true)

        _ = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: versionInfo)

        #expect(gitHandler.message == "Update version to \(releaseVersion)")
    }

    @Test("Skips version update when user denies permission")
    func skipsUpdateWithoutPermission() throws {
        let currentVersion = "1.0.0"
        let releaseVersion = "2.0.0"
        let versionInfo = makeVersionInfo(.version(releaseVersion))
        let (sut, gitHandler) = makeSUT(currentVersion: currentVersion, shouldUpdate: true, grantPermission: false)

        _ = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: versionInfo)

        #expect(gitHandler.message == nil)
    }

    @Test("Skips update when no current version detected")
    func skipsUpdateWithoutCurrentVersion() throws {
        let releaseVersion = "2.0.0"
        let versionInfo = makeVersionInfo(.version(releaseVersion))
        let (sut, gitHandler) = makeSUT(currentVersion: nil, shouldUpdate: true, grantPermission: true)

        _ = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: versionInfo)

        #expect(gitHandler.message == nil)
    }

    @Test("Skips update when service says not to update")
    func skipsUpdateWhenServiceSaysNo() throws {
        let currentVersion = "2.0.0"
        let releaseVersion = "2.0.0"
        let versionInfo = makeVersionInfo(.version(releaseVersion))
        let (sut, gitHandler) = makeSUT(currentVersion: currentVersion, shouldUpdate: false, grantPermission: true)

        _ = try sut.selectNextVersionNumber(projectPath: "/project", versionInfo: versionInfo)

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
