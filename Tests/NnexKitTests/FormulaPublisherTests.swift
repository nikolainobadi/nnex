//
//  FormulaPublisherTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import Testing
import Foundation
import NnexSharedTestHelpers
@testable import NnexKit

struct FormulaPublisherTests {
    private let tapFolderPath = "/test/tap/folder"
    private let content = "formula content"
    private let formulaName = "testFormula"

    private var formulaFileName: String {
        return "\(formulaName).rb"
    }
}


// MARK: - Unit Tests
extension FormulaPublisherTests {
    @Test("Creates new formula file when no previous formula exists")
    func createsNewFormulaFile() throws {
        let (sut, fileSystem, formulaFolder, _) = makeSUT()

        let filePath = try sut.publishFormula(content, formulaName: formulaName, commitMessage: nil, tapFolderPath: tapFolderPath)

        #expect(formulaFolder.containsFile(named: formulaFileName))
        #expect(filePath == "\(tapFolderPath)/Formula/\(formulaFileName)")
        #expect(fileSystem.capturedPaths == [tapFolderPath])
    }

    @Test("Deletes existing formula file before creating new one")
    func deletesExistingFormulaFile() throws {
        let (sut, _, formulaFolder, _) = makeSUT(existingFile: formulaFileName)

        #expect(formulaFolder.containsFile(named: formulaFileName))

        _ = try sut.publishFormula(content, formulaName: formulaName, commitMessage: nil, tapFolderPath: tapFolderPath)

        #expect(formulaFolder.containsFile(named: formulaFileName))
    }

    @Test("Does not commit and push changes if no commit message is provided")
    func doesNotCommitAndPush() throws {
        let (sut, _, _, gitHandler) = makeSUT()

        _ = try sut.publishFormula(content, formulaName: formulaName, commitMessage: nil, tapFolderPath: tapFolderPath)

        #expect(gitHandler.message == nil)
    }

    @Test("Commits changes and pushes tap folder when a commit message is provided")
    func commitAndPushTapFolder() throws {
        let commitMessage = "commit message"
        let (sut, _, _, gitHandler) = makeSUT()

        _ = try sut.publishFormula(content, formulaName: formulaName, commitMessage: commitMessage, tapFolderPath: tapFolderPath)

        #expect(gitHandler.message == commitMessage)
        #expect(gitHandler.path == tapFolderPath)
    }
}


// MARK: - SUT
private extension FormulaPublisherTests {
    func makeSUT(existingFile: String? = nil, throwError: Bool = false) -> (sut: FormulaPublisher, fileSystem: MockFileSystem, formulaFolder: MockDirectory, gitHandler: MockGitHandler) {
        let formulaFolder = MockDirectory(path: "\(tapFolderPath)/Formula", containedFiles: existingFile != nil ? [existingFile!] : [])
        let tapFolder = MockDirectory(path: tapFolderPath, subdirectories: [formulaFolder])
        let fileSystem = MockFileSystem(directoryMap: [tapFolderPath: tapFolder])
        let gitHandler = MockGitHandler(throwError: throwError)
        let sut = FormulaPublisher(gitHandler: gitHandler, fileSystem: fileSystem)

        return (sut, fileSystem, formulaFolder, gitHandler)
    }
}
