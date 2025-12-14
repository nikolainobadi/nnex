//
//  GithubReleaseControllerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit
import Testing
import Foundation
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex

final class GithubReleaseControllerTests {
    @Test("Starting values empty")
    func startingValuesEmpty() {
        let (_, gitHandler) = makeSUT()
        
        #expect(gitHandler.releaseVersion == nil)
        #expect(gitHandler.releaseNoteInfo == nil)
    }
}


// MARK: - SUT
private extension GithubReleaseControllerTests {
    func makeSUT(date: Date = Date(), inputResults: [String] = [], selectionIndex: Int = 0, permissionResults: [Bool] = [], desktop: (any Directory)? = nil, filePathToReturn: String? = nil) -> (sut: GithubReleaseController, gitHandler: MockGitHandler) {
        let gitHandler = MockGitHandler()
        let fileSystem = MockFileSystem(desktop: desktop)
        let picker = MockSwiftPicker(
            inputResult: .init(type: .ordered(inputResults)),
            permissionResult: .init(type: .ordered(permissionResults)),
            selectionResult: .init(defaultSingle: .index(selectionIndex))
        )
        let folderBrowser = MockDirectoryBrowser(filePathToReturn: filePathToReturn, directoryToReturn: nil)
        let dateProvider = MockDateProvider(date: date)
        let sut = GithubReleaseController(
            picker: picker,
            gitHandler: gitHandler,
            fileSystem: fileSystem,
            dateProvider: dateProvider,
            folderBrowser: folderBrowser
        )
        
        return (sut, gitHandler)
    }
    
    func makeAssets() -> [ArchivedBinary] {
        return [
            .init(originalPath: "/tmp/App", archivePath: "/tmp/App.tar.gz", sha256: "abc123")
        ]
    }
    
    func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: date)
    }
}


// MARK: - Picker
private extension GithubReleaseControllerTests {
    static func makePicker(inputResults: [String] = [], selectionIndex: Int = 0, permissionResults: [Bool] = []) -> MockSwiftPicker {
        MockSwiftPicker(
            inputResult: .init(type: .ordered(inputResults)),
            permissionResult: .init(type: .ordered(permissionResults)),
            selectionResult: .init(defaultSingle: .index(selectionIndex))
        )
    }
}
