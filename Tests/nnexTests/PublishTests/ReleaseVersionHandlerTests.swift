//
//  ReleaseVersionHandlerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/12/25.
//

import Testing
import Foundation
import NnexKit
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor
final class ReleaseVersionHandlerTests {
    private let projectFolder: Folder
    private let testProjectPath = "/path/to/project"
    private let testPreviousVersion = "v1.0.0"
    private let testVersionNumber = "2.0.0"
    
    init() throws {
        let tempFolder = Folder.temporary
        self.projectFolder = try tempFolder.createSubfolder(named: "ReleaseVersionHandler-\(UUID().uuidString)")
    }
    
    deinit {
        deleteFolderContents(projectFolder)
    }
}


// MARK: - Version Resolution with Provided Version Info
extension ReleaseVersionHandlerTests {
    @Test("Resolves version when version info is provided directly")
    func resolvesVersionWhenVersionInfoProvided() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let sut = makeSUT(previousVersion: testPreviousVersion).sut
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(
            versionInfo: versionInfo,
            projectPath: testProjectPath
        )
        
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
        
        let (sut, _, _) = makeSUT(previousVersion: testPreviousVersion)
        
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(
            versionInfo: versionInfo,
            projectPath: testProjectPath
        )
        
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
        
        let (sut, _, _) = makeSUT(previousVersion: nil)
        
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(
            versionInfo: versionInfo,
            projectPath: testProjectPath
        )
        
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
        let (sut, _, _) = makeSUT(
            previousVersion: testPreviousVersion,
            inputResponses: [testVersionNumber]
        )
        
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
        if case .version(let version) = resolvedVersion {
            #expect(version == testVersionNumber)
        } else {
            Issue.record("Expected version type but got \(resolvedVersion)")
        }
        
        #expect(previousVersion == testPreviousVersion)
    }
    
    @Test("Shows previous version in prompt when available")
    func showsPreviousVersionInPrompt() throws {
        let (sut, _, picker) = makeSUT(
            previousVersion: testPreviousVersion,
            inputResponses: ["1.5.0"]
        )
        
        let (resolvedVersion, _) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
        if case .version(let version) = resolvedVersion {
            #expect(version == "1.5.0")
        } else {
            Issue.record("Expected version type")
        }
        
        // Verify the prompt included previous version info
        #expect(picker.lastPrompt?.contains(testPreviousVersion) == true)
        #expect(picker.lastPrompt?.contains("major") == true)
        #expect(picker.lastPrompt?.contains("minor") == true)
        #expect(picker.lastPrompt?.contains("patch") == true)
    }
    
    @Test("Shows default format hint when no previous version")
    func showsDefaultFormatWhenNoPreviousVersion() throws {
        let (sut, _, picker) = makeSUT(
            previousVersion: nil,
            inputResponses: ["1.0.0"]
        )
        
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
        if case .version(let version) = resolvedVersion {
            #expect(version == "1.0.0")
        } else {
            Issue.record("Expected version type")
        }
        
        #expect(previousVersion == nil)
        #expect(picker.lastPrompt?.contains("v1.1.0 or 1.1.0") == true)
    }
    
    @Test("Updates source code version if it exists")
    func updatesExistingVersionInSource() throws {
        let newVersion = "2.0.0"
        let previousVersionNumber = "1.0.0"
        let mockFilePath = try createMockCommandFile(previousVersion: previousVersionNumber)
        let sut = makeSUT(permissionResponses: [true]).sut
        let _ = try sut.resolveVersionInfo(versionInfo: .version(newVersion), projectPath: projectFolder.path)
        let updatedFile = try File(path: mockFilePath)
        let contents = try updatedFile.readAsString()
        
        #expect(contents.contains("2.0.0"), "File should contain version 2.0.0")
    }
}


// MARK: - Increment Keywords
extension ReleaseVersionHandlerTests {
    @Test("Handles major increment keyword")
    func handlesMajorIncrement() throws {
        let (sut, _, _) = makeSUT(
            previousVersion: testPreviousVersion,
            inputResponses: ["major"]
        )
        
        let (resolvedVersion, _) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
        if case .increment(let part) = resolvedVersion {
            #expect(part == .major)
        } else {
            Issue.record("Expected increment type with major")
        }
    }
    
    @Test("Handles minor increment keyword")
    func handlesMinorIncrement() throws {
        let (sut, _, _) = makeSUT(
            previousVersion: testPreviousVersion,
            inputResponses: ["minor"]
        )
        
        let (resolvedVersion, _) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
        if case .increment(let part) = resolvedVersion {
            #expect(part == .minor)
        } else {
            Issue.record("Expected increment type with minor")
        }
    }
    
    @Test("Handles patch increment keyword")
    func handlesPatchIncrement() throws {
        let (sut, _, _) = makeSUT(
            previousVersion: testPreviousVersion,
            inputResponses: ["patch"]
        )
        
        let (resolvedVersion, _) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
        if case .increment(let part) = resolvedVersion {
            #expect(part == .patch)
        } else {
            Issue.record("Expected increment type with patch")
        }
    }
    
    @Test("Treats non-keyword input as version number")
    func treatsNonKeywordAsVersion() throws {
        let customVersion = "3.2.1"
        let (sut, _, _) = makeSUT(
            previousVersion: testPreviousVersion,
            inputResponses: [customVersion]
        )
        
        let (resolvedVersion, _) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
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
        let (sut, _, _) = makeSUT(
            previousVersion: testPreviousVersion,
            shouldThrowPickerError: true
        )
        
        #expect(throws: (any Error).self) {
            try sut.resolveVersionInfo(
                versionInfo: nil,
                projectPath: testProjectPath
            )
        }
    }
    
    @Test("Handles git error gracefully when getting previous version")
    func handlesGitErrorGracefully() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let (sut, _, _) = makeSUT(
            previousVersion: nil,
            shouldThrowGitError: true
        )
        
        // Should not throw because getPreviousReleaseVersion uses try?
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(
            versionInfo: versionInfo,
            projectPath: testProjectPath
        )
        
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
        let (sut, _, _) = makeSUT(
            previousVersion: nil,
            shouldThrowGitError: true,
            inputResponses: ["1.0.0"]
        )
        
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
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
        let (sut, _, _) = makeSUT(
            previousVersion: testPreviousVersion,
            inputResponses: ["v2.0.0"]
        )
        
        let (resolvedVersion, _) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
        if case .version(let version) = resolvedVersion {
            #expect(version == "v2.0.0")
        } else {
            Issue.record("Expected version type")
        }
    }
    
    @Test("Handles version without 'v' prefix")
    func handlesVersionWithoutVPrefix() throws {
        let (sut, _, _) = makeSUT(
            previousVersion: "1.0.0", // No 'v' prefix
            inputResponses: ["2.0.0"]
        )
        
        let (resolvedVersion, previousVersion) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
        if case .version(let version) = resolvedVersion {
            #expect(version == "2.0.0")
        } else {
            Issue.record("Expected version type")
        }
        
        #expect(previousVersion == "1.0.0")
    }
    
    @Test("Handles empty input by treating as version")
    func handlesEmptyInput() throws {
        let emptyVersion = ""
        let (sut, _, _) = makeSUT(
            previousVersion: testPreviousVersion,
            inputResponses: [emptyVersion]
        )
        
        let (resolvedVersion, _) = try sut.resolveVersionInfo(
            versionInfo: nil,
            projectPath: testProjectPath
        )
        
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
        shouldThrowPickerError: Bool = false,
        inputResponses: [String] = [],
        permissionResponses: [Bool] = []
    ) -> (sut: ReleaseVersionHandler, gitHandler: MockGitHandler, picker: MockPicker) {
        
        let gitHandler: MockGitHandler
        if let previousVersion = previousVersion {
            gitHandler = MockGitHandler(
                previousVersion: previousVersion,
                throwError: shouldThrowGitError
            )
        } else {
            // When no previous version exists, MockGitHandler should throw 
            // so that try? converts it to nil
            gitHandler = MockGitHandler(
                previousVersion: "",
                throwError: true
            )
        }
        
        let picker = MockPicker(
            inputResponses: inputResponses,
            permissionResponses: permissionResponses,
            shouldThrowError: shouldThrowPickerError
        )
        
        let shell = MockShell()
        let sut = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler, shell: shell)
        
        return (sut, gitHandler, picker)
    }
    
    func createMockCommandFile(previousVersion: String) throws -> String {
        let fileContents = """
        import ArgumentParser

        @main
        struct MockCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                abstract: "",
                version: "\(previousVersion)",
            )
        }
        """

        let file = try projectFolder.createSubfolderIfNeeded(withName: "Sources").createFile(named: "MockCommand.swift")
        try file.write(fileContents)

        return file.path
    }
}
