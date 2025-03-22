//
//  FormulaPublisherTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import Files
import Testing
import Foundation
import NnexSharedTestHelpers
@testable import NnexKit

final class FormulaPublisherTests {
    private let tapFolder: Folder
    private let content = "formula content"
    private let formulaName = "testFormula"
    
    private var formulaFileName: String {
        return "\(formulaName).rb"
    }
    
    init() throws {
        self.tapFolder = try Folder.temporary.createSubfolder(named: "testTapFolder_\(UUID().uuidString)")
    }
    
    deinit {
        deleteFolderContents(tapFolder)
    }
}


// MARK: - Unit Tests
extension FormulaPublisherTests {
    @Test("Creates new formula file when no previous formula exists")
    func createsNewFormulaFile() throws {
        let sut = makeSUT().sut
        let formulaFile = try requireFormulaFile(sut: sut)
        let savedContents = try #require(try formulaFile.readAsString())
        
        #expect(savedContents == content)
        #expect(formulaFile.name == formulaFileName)
        #expect(tapFolder.containsFile(named: formulaFileName))
    }
    
    @Test("Overwrites existing formula file")
    func overwritesExistingFormulaFile() throws {
        let sut = makeSUT().sut
        let previousContent = "previous content"
        let previousFile = try #require(try tapFolder.createFile(named: formulaFileName))
        
        try previousFile.write(previousContent)
        
        let formulaFile = try requireFormulaFile(sut: sut)
        let savedContents = try #require(try formulaFile.readAsString())
        
        #expect(savedContents == content)
        #expect(formulaFile.name == formulaFileName)
        #expect(tapFolder.containsFile(named: formulaFileName))
    }
    
    @Test("Does not commit and push changes if no commit message is provided")
    func doesNotCommitAndPush() throws {
        let (sut, gitHandler) = makeSUT()
        
        try requireFormulaFile(sut: sut)
        
        #expect(gitHandler.message == nil)
        #expect(tapFolder.files.count() == 1)
    }
    
    @Test("Commits changes and pushes tap folder when a commit message is provided")
    func commitAndPushTapFolder() throws {
        let commitMessage = "commit message"
        let (sut, gitHandler) = makeSUT()
        
        try requireFormulaFile(sut: sut, commitMessage: commitMessage)
        
        #expect(gitHandler.message == commitMessage)
        #expect(tapFolder.files.count() == 1)
    }
}


// MARK: - SUT
private extension FormulaPublisherTests {
    func makeSUT(throwError: Bool = false) -> (sut: FormulaPublisher, gitHandler: MockGitHandler) {
        let gitHandler = MockGitHandler(throwError: throwError)
        let sut = FormulaPublisher(gitHandler: gitHandler)
        
        return (sut, gitHandler)
    }
}


// MARK: - Helpers
private extension FormulaPublisherTests {
    @discardableResult
    func requireFormulaFile(sut: FormulaPublisher, commitMessage: String? = nil) throws -> File {
        let path = try #require(try sut.publishFormula(content, formulaName: formulaName, commitMessage: commitMessage, tapFolderPath: tapFolder.path))
        let file = try #require(try File(path: path))
        
        return file
    }
}
