//
//  ReleaseVersionHandlerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/12/25.
//

import NnexKit
import Testing
import Foundation
import NnShellTesting
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

struct ReleaseVersionHandlerTests {
    private let testProjectPath = "/path/to/project"
    private let testPreviousVersion = "v1.0.0"
    private let testVersionNumber = "2.0.0"
}


// MARK: - Version Resolution with Provided Version Info
extension ReleaseVersionHandlerTests {
    @Test("Resolves version when version info is provided directly")
    func resolvesVersionWhenVersionInfoProvided() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let sut = makeSUT(previousVersion: testPreviousVersion).sut
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(versionInfo: versionInfo, projectPath: testProjectPath)
        
        if case .version(let version) = resolvedVersion,
           case .version(let expectedVersion) = versionInfo {
            #expect(version == expectedVersion)
        } else {
            Issue.record("Expected version types to match")
        }
        #expect(previousVersion == testPreviousVersion)
    }
    
    @Test("Resolves version with increment when version info is increment type")
    func resolvesVersionWithIncrementType() throws {
        let versionInfo = ReleaseVersionInfo.increment(.minor)
        let sut = makeSUT(previousVersion: testPreviousVersion).sut
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(versionInfo: versionInfo, projectPath: testProjectPath)
        
        if case .increment(let part) = resolvedVersion,
           case .increment(let expectedPart) = versionInfo {
            #expect(part == expectedPart)
        } else {
            Issue.record("Expected increment types to match")
        }
        #expect(previousVersion == testPreviousVersion)
    }
    
    @Test("Returns nil previous version when no tags exist")
    func returnsNilPreviousVersionWhenNoTags() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let sut = makeSUT(previousVersion: nil).sut
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(versionInfo: versionInfo, projectPath: testProjectPath)
        
        if case .version(let version) = resolvedVersion,
           case .version(let expectedVersion) = versionInfo {
            #expect(version == expectedVersion)
        } else {
            Issue.record("Expected version types to match")
        }
        #expect(previousVersion == nil)
    }
}


// MARK: - Version Resolution with User Input
extension ReleaseVersionHandlerTests {
    @Test("Prompts for version when no version info provided")
    func promptsForVersionWhenNoVersionInfoProvided() throws {
        let sut = makeSUT(previousVersion: testPreviousVersion, inputResponses: [testVersionNumber]).sut
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(versionInfo: nil, projectPath: testProjectPath)
        
        if case .version(let version) = resolvedVersion {
            #expect(version == testVersionNumber)
        } else {
            Issue.record("Expected version type but got \(resolvedVersion)")
        }
        
        #expect(previousVersion == testPreviousVersion)
    }
}


// MARK: - Increment Keywords
extension ReleaseVersionHandlerTests {
    @Test("Handles major increment keyword")
    func handlesMajorIncrement() throws {
        let sut = makeSUT(previousVersion: testPreviousVersion, inputResponses: ["major"]).sut
        let (resolvedVersion, _) = try sut.resolveVersionInfo(versionInfo: nil, projectPath: testProjectPath)
        
        if case .increment(let part) = resolvedVersion {
            #expect(part == .major)
        } else {
            Issue.record("Expected increment type with major")
        }
    }
    
    @Test("Handles minor increment keyword")
    func handlesMinorIncrement() throws {
        let sut = makeSUT(previousVersion: testPreviousVersion, inputResponses: ["minor"]).sut
        let (resolvedVersion, _) = try sut.resolveVersionInfo(versionInfo: nil, projectPath: testProjectPath)
        
        if case .increment(let part) = resolvedVersion {
            #expect(part == .minor)
        } else {
            Issue.record("Expected increment type with minor")
        }
    }
    
    @Test("Handles patch increment keyword")
    func handlesPatchIncrement() throws {
        let sut = makeSUT(previousVersion: testPreviousVersion, inputResponses: ["patch"]).sut
        let (resolvedVersion, _) = try sut.resolveVersionInfo(versionInfo: nil, projectPath: testProjectPath)
        
        if case .increment(let part) = resolvedVersion {
            #expect(part == .patch)
        } else {
            Issue.record("Expected increment type with patch")
        }
    }
    
    @Test("Treats non-keyword input as version number")
    func treatsNonKeywordAsVersion() throws {
        let customVersion = "3.2.1"
        let sut = makeSUT(previousVersion: testPreviousVersion, inputResponses: [customVersion]).sut
        let (resolvedVersion, _) = try sut.resolveVersionInfo(versionInfo: nil, projectPath: testProjectPath)
        
        if case .version(let version) = resolvedVersion {
            #expect(version == customVersion)
        } else {
            Issue.record("Expected version type with custom version")
        }
    }
}


// MARK: - Error Handling
extension ReleaseVersionHandlerTests {
    @Test("Throws error when picker fails")
    func throwsErrorWhenPickerFails() throws {
        let sut = makeSUT(previousVersion: testPreviousVersion).sut

        #expect(throws: (any Error).self) {
            try sut.resolveVersionInfo(versionInfo: nil, projectPath: testProjectPath)
        }
    }
    
    @Test("Handles git error gracefully when getting previous version")
    func handlesGitErrorGracefully() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let sut = makeSUT(previousVersion: nil, shouldThrowGitError: true).sut
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(versionInfo: versionInfo, projectPath: testProjectPath)
        
        if case .version(let version) = resolvedVersion,
           case .version(let expectedVersion) = versionInfo {
            #expect(version == expectedVersion)
        } else {
            Issue.record("Expected version types to match")
        }
        #expect(previousVersion == nil)
    }
    
    @Test("Prompts for input when git fails and no version provided")
    func promptsWhenGitFailsAndNoVersion() throws {
        let sut = makeSUT(previousVersion: nil, shouldThrowGitError: true, inputResponses: ["1.0.0"]).sut
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(versionInfo: nil, projectPath: testProjectPath)
        
        if case .version(let version) = resolvedVersion {
            #expect(version == "1.0.0")
        } else {
            Issue.record("Expected version type")
        }
        
        #expect(previousVersion == nil)
    }
}


// MARK: - Edge Cases
extension ReleaseVersionHandlerTests {
    @Test("Handles version with 'v' prefix")
    func handlesVersionWithVPrefix() throws {
        let sut = makeSUT(previousVersion: testPreviousVersion, inputResponses: ["v2.0.0"]).sut
        let (resolvedVersion, _) = try sut.resolveVersionInfo(versionInfo: nil, projectPath: testProjectPath)
        
        if case .version(let version) = resolvedVersion {
            #expect(version == "v2.0.0")
        } else {
            Issue.record("Expected version type")
        }
    }
    
    @Test("Handles version without 'v' prefix")
    func handlesVersionWithoutVPrefix() throws {
        let sut = makeSUT(previousVersion: "1.0.0", inputResponses: ["2.0.0"]).sut
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(versionInfo: nil, projectPath: testProjectPath)
        
        if case .version(let version) = resolvedVersion {
            #expect(version == "2.0.0")
        } else {
            Issue.record("Expected version type")
        }
        
        #expect(previousVersion == "1.0.0")
    }
    
    // TODO: - what does this even test? what is its purpose?
    @Test("Handles empty input by treating as version", .disabled())
    func handlesEmptyInput() throws {
        let emptyVersion = ""
        let sut = makeSUT(previousVersion: testPreviousVersion, inputResponses: [emptyVersion]).sut
        let (resolvedVersion, _) = try sut.resolveVersionInfo(versionInfo: nil, projectPath: testProjectPath)
        
        // Empty string should be treated as a version (not an increment)
        if case .version(let version) = resolvedVersion {
            #expect(version == emptyVersion)
        } else {
            Issue.record("Expected version type for empty input")
        }
    }
}


// MARK: - Test Helpers
private extension ReleaseVersionHandlerTests {
    func makeSUT(
        previousVersion: String? = nil,
        shouldThrowGitError: Bool = false,
        inputResponses: [String] = [],
        permissionResponses: [Bool] = []
    ) -> (sut: ReleaseVersionHandler, gitHandler: MockGitHandler) {
        
        let gitHandler: MockGitHandler
        if let previousVersion = previousVersion {
            gitHandler = MockGitHandler(previousVersion: previousVersion, throwError: shouldThrowGitError)
        } else {
            // When no previous version exists, MockGitHandler should throw 
            // so that try? converts it to nil
            gitHandler = MockGitHandler(previousVersion: "", throwError: true)
        }
        
        let fileSystem = MockFileSystem()
        let picker = MockSwiftPicker(inputResult: .init(type: .ordered(inputResponses)))
        let sut = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler, shell: MockShell(), fileSystem: fileSystem)
        
        return (sut, gitHandler)
    }
}
