//
//  AIReleaseNotesHandlerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 9/9/25.
//

import Testing
import Foundation
import NnShellKit
import NnexSharedTestHelpers
import NnexKit
@testable import nnex
@preconcurrency import Files

@MainActor
final class AIReleaseNotesHandlerTests {
    private let projectName = "TestProject"
    private let releaseNumber = "1.2.3"
    private let projectFolder: Folder
    private let testChangelog = """
    # Changelog

    ## [Unreleased]
    - Some unreleased change

    ## [1.2.3] - 2025-09-09
    ### Added
    - New feature X
    - New feature Y

    ### Fixed
    - Bug fix A

    ## [1.2.2] - 2025-09-01
    - Previous release
    """

    init() throws {
        let tempFolder = Folder.temporary
        self.projectFolder = try tempFolder.createSubfolder(named: "TestFolder\(UUID().uuidString)")
    }

    deinit {
        deleteFolderContents(projectFolder)
    }
}


// MARK: - generateReleaseNotes Tests
extension AIReleaseNotesHandlerTests {
    @Test("Returns existing changelog content when version found")
    func returnsExistingChangelogContent() throws {
        let (sut, _, _) = makeSUT()
        
        // Create CHANGELOG.md file in project folder
        try createChangelog(content: testChangelog)
        
        let result = try sut.generateReleaseNotes(releaseNumber: releaseNumber, projectPath: projectFolder.path)
        
        #expect(result.isFromFile == false)
        #expect(result.content.contains("New feature X"))
        #expect(result.content.contains("Bug fix A"))
    }
    
    @Test("Generates new notes when changelog exists but version not found")
    func generatesNewNotesWhenVersionNotInChangelog() throws {
        let changelogWithoutVersion = """
        # Changelog
        
        ## [Unreleased]
        - Some change
        
        ## [1.0.0] - 2025-01-01
        - Old release
        """
        
        let testContent = "Generated release notes content"
        let (sut, shell, _) = makeSUT(
            fileContent: testContent,
            permissionResponses: [true]
        )
        
        // Create CHANGELOG.md file without our version
        try createChangelog(content: changelogWithoutVersion)
        
        let result = try sut.generateReleaseNotes(releaseNumber: releaseNumber, projectPath: projectFolder.path)
        
        // Verify Claude command was executed since version not found
        #expect(shell.executedCommands.contains { $0.contains("claude code edit") })
        #expect(result.isFromFile == true)
    }
    
    @Test("Handles empty file with successful retry")
    func handlesEmptyFileWithRetry() throws {
        let (sut, _, _) = makeSUT(
            fileContent: "", // Initially empty
            permissionResponses: [true, true], // Confirm creation, then confirm retry
            shouldUseRetryFile: true
        )
        
        let result = try sut.generateReleaseNotes(releaseNumber: releaseNumber, projectPath: projectFolder.path)
        
        #expect(result.isFromFile == true)
    }


}


// MARK: - CHANGELOG.md Parsing Tests
extension AIReleaseNotesHandlerTests {
    @Test("Parses single section changelog correctly")
    func parsesSingleSectionChangelog() throws {
        let singleSectionChangelog = """
        # Changelog
        
        ## [1.2.3] - 2025-09-09
        ### Added
        - Feature A
        - Feature B
        
        ### Fixed
        - Bug X
        """
        
        let (sut, _, _) = makeSUT()
        
        try createChangelog(content: singleSectionChangelog)
        
        let result = try sut.generateReleaseNotes(releaseNumber: releaseNumber, projectPath: projectFolder.path)
        
        #expect(result.content.contains("Feature A"))
        #expect(result.content.contains("Bug X"))
        #expect(!result.content.contains("## [1.2.3]")) // Should not include header
    }
    
    @Test("Handles changelog with empty version section")
    func handlesChangelogWithEmptyVersionSection() throws {
        let emptyVersionChangelog = """
        # Changelog
        
        ## [1.2.3] - 2025-09-09
        
        ## [1.2.2] - 2025-09-01
        - Previous content
        """
        
        let (sut, shell, _) = makeSUT(
            fileContent: "Generated content",
            permissionResponses: [true]
        )
        
        try createChangelog(content: emptyVersionChangelog)
        
        let result = try sut.generateReleaseNotes(releaseNumber: releaseNumber, projectPath: projectFolder.path)
        
        // Should generate new notes since version section is empty
        #expect(shell.executedCommands.contains { $0.contains("claude code edit") })
        #expect(result.isFromFile == true)
    }
}


// MARK: - SUT
private extension AIReleaseNotesHandlerTests {
    func makeSUT(
        fileContent: String = "Test content",
        permissionResponses: [Bool] = [true],
        shouldUseRetryFile: Bool = false
    ) -> (sut: AIReleaseNotesHandler, shell: MockShell, picker: MockPicker) {
        
        let shell = MockShell()
        
        let picker = MockPicker(
            selectedItemIndices: [],
            inputResponses: [],
            permissionResponses: permissionResponses,
            shouldThrowError: false
        )
        
        let fileSystem: any FileSystemProvider
        if shouldUseRetryFile {
            fileSystem = MockFileSystemProviderWithRetry(fileContent: fileContent)
        } else {
            fileSystem = MockFileSystemProvider(fileContent: fileContent)
        }
        
        let dateProvider = MockDateProvider(date: Date())
        
        let fileUtility = ReleaseNotesFileUtility(
            picker: picker,
            fileSystem: fileSystem,
            dateProvider: dateProvider
        )
        
        let sut = AIReleaseNotesHandler(
            projectName: projectName,
            shell: shell,
            picker: picker,
            fileUtility: fileUtility
        )
        
        return (sut, shell, picker)
    }
    
    func createChangelog(content: String) throws {
        try projectFolder.createFile(named: "CHANGELOG.md").write(content)
    }
}


// MARK: - Test Helpers
private class MockFileSystemProviderWithRetry: FileSystemProvider {
    private(set) var createdFileName: String = ""
    private(set) var createdFilePath: String = ""
    private let fileContent: String
    
    init(fileContent: String = "") {
        self.fileContent = fileContent
    }
    
    func createFile(in folderPath: String, named: String) throws -> FileProtocol {
        createdFileName = named
        createdFilePath = "\(folderPath)/\(named)"
        
        return MockFileWithRetry(
            path: createdFilePath,
            initialContent: "",
            retryContent: "Test content after retry"
        )
    }
}

private class MockFileWithRetry: FileProtocol {
    let path: String
    private let initialContent: String
    private let retryContent: String
    private var readCount = 0
    
    init(path: String, initialContent: String, retryContent: String) {
        self.path = path
        self.initialContent = initialContent
        self.retryContent = retryContent
    }
    
    func readAsString() throws -> String {
        defer { readCount += 1 }
        return readCount == 0 ? initialContent : retryContent
    }
}
