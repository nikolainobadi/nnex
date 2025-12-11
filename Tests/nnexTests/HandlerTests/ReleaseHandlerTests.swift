//
//  ReleaseHandlerTests.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Testing
import NnexKit
import Foundation
import GitCommandGen
import NnShellTesting
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

struct ReleaseHandlerTests {
    private let testProjectName = "TestProject"
    private let testBinaryPath = "/path/to/binary"
    private let testBinarySha256 = "abc123def456"
    private let testAssetURL = "https://github.com/test/repo/releases/download/v1.0.0/binary"
    private let testPreviousVersion = "v0.9.0"
    private let testVersionNumber = "1.0.0"
    private let testReleaseNotes = "Test release notes content"
    private let testReleaseNotesFile = "/path/to/notes.md"
}


// MARK: - Unit Tests
extension ReleaseHandlerTests {
    
}


// MARK: - SUT
private extension ReleaseHandlerTests {
    func makeSUT(filePathToReturn: String? = nil, directoryToReturn: (any Directory)? = nil) {
        let picker = MockSwiftPicker()
        let gitHandler = MockGitHandler()
        let filesSystem = MockFileSystem()
        let folderBrowser = MockDirectoryBrowser(filePathToReturn: filePathToReturn, directoryToReturn: directoryToReturn)
        let sut = ReleaseHandler(picker: picker, gitHandler: gitHandler, fileSystem: filesSystem, folderBrowser: folderBrowser)
    }
}
 

