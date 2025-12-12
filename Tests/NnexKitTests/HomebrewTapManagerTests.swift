//
//  HomebrewTapManagerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import Testing
import Foundation
import NnShellTesting
import NnexSharedTestHelpers
@testable import NnexKit

final class HomebrewTapManagerTests {
    @Test("Starting values empty")
    func emptyStartingValues() {
        let (_, store, _) = makeSUT()
        
        #expect(store.savedTap == nil)
        #expect(store.savedPath == nil)
        #expect(store.savedFormulas.isEmpty)
    }
    
    @Test("Does not create tap when GitHub CLI is missing")
    func createNewTapMissingGHCLIFails() {
        let parent = MockDirectory(path: "/taps")
        let (sut, store, gitHandler) = makeSUT(ghIsInstalled: false)
        
        #expect(throws: NnexError.self) {
            try sut.createNewTap(named: "tap", details: "details", in: parent, isPrivate: false)
        }
        
        #expect(store.savedTap == nil)
        #expect(store.savedFormulas.isEmpty)
        #expect(gitHandler.gitInitPath == nil)
        #expect(gitHandler.remoteTapName == nil)
        #expect(parent.subdirectories.isEmpty)
    }
    
    @Test("Saves tap list folder path")
    func saveTapListFolderPath() {
        let (sut, store, _) = makeSUT()
        let path = "/path/to/taps"
        
        sut.saveTapListFolderPath(path: path)
        
        #expect(store.savedPath == path)
    }
    
    @Test("Creates tap folder, initializes git, and saves tap")
    func createNewTapSuccess() throws {
        let tapName = "myTap"
        let tapList = MockDirectory(path: "/taps")
        let remotePath = "https://github.com/user/homebrew-myTap"
        let (sut, store, gitHandler) = makeSUT(remoteURL: remotePath)
        
        try sut.createNewTap(named: tapName, details: "details", in: tapList, isPrivate: true)
        
        let createdTapFolder = try #require(tapList.subdirectories.first as? MockDirectory)
        let formulaFolder = try #require(createdTapFolder.subdirectories.first)
        let savedTap = try #require(store.savedTap)
        
        #expect(createdTapFolder.name == tapName.homebrewTapName)
        #expect(formulaFolder.name == "Formula")
        #expect(gitHandler.gitInitPath == createdTapFolder.path)
        #expect(gitHandler.remoteTapName == createdTapFolder.name)
        #expect(gitHandler.remoteTapPath == createdTapFolder.path)
        #expect(savedTap.name == createdTapFolder.name)
        #expect(savedTap.localPath == createdTapFolder.path)
        #expect(savedTap.remotePath == remotePath)
        #expect(store.savedFormulas.isEmpty)
    }
    
    @Test("Throws when git handler fails during tap creation")
    func createNewTapGitError() {
        let tapList = MockDirectory(path: "/taps")
        let (sut, store, gitHandler) = makeSUT(gitThrows: true)
        
        #expect(throws: (any Error).self) {
            try sut.createNewTap(named: "tap", details: "details", in: tapList, isPrivate: false)
        }
        
        #expect(store.savedTap == nil)
        #expect(store.savedPath == nil)
        #expect(gitHandler.remoteTapName == nil)
    }
    
    @Test("Throws when persisting new tap fails")
    func createNewTapStoreError() {
        let tapList = MockDirectory(path: "/taps")
        let (sut, store, gitHandler) = makeSUT(storeThrows: true)
        
        #expect(throws: (any Error).self) {
            try sut.createNewTap(named: "tap", details: "details", in: tapList, isPrivate: false)
        }
        
        #expect(store.savedTap == nil)
        #expect(gitHandler.remoteTapName == tapList.subdirectories.first?.name)
    }
    
    @Test("Imports existing tap and formulas")
    func importTapSuccess() throws {
        let formulaContent = """
        class MyTool < Formula
        desc "A useful tool"
        homepage "https://example.com"
        license "MIT"
        end
        """
        let formulaFolder = MockDirectory(path: "/taps/homebrew-myTap/Formula", containedFiles: ["mytool.rb"])
        formulaFolder.fileContents["mytool.rb"] = formulaContent
        let tapFolder = MockDirectory(path: "/taps/homebrew-myTap", subdirectories: [formulaFolder])
        let remotePath = "https://github.com/user/homebrew-myTap"
        let (sut, store, _) = makeSUT(remoteURL: remotePath)
        
        let result = try sut.importTap(from: tapFolder)
        
        let savedTap = try #require(store.savedTap)
        let savedFormula = try #require(store.savedFormulas.first)
        
        #expect(savedTap.name == "myTap")
        #expect(savedTap.localPath == tapFolder.path)
        #expect(savedTap.remotePath == remotePath)
        #expect(store.savedFormulas.count == 1)
        #expect(savedFormula.name == "MyTool")
        #expect(savedFormula.details == "A useful tool")
        #expect(savedFormula.homepage == "https://example.com")
        #expect(savedFormula.license == "MIT")
        #expect(result.warnings.isEmpty)
    }
    
    @Test("Imports tap even when no formula folder exists")
    func importTapWithoutFormulaFolder() throws {
        let tapFolder = MockDirectory(path: "/taps/homebrew-myTap")
        let (sut, store, _) = makeSUT(remoteURL: "remote")
        
        let result = try sut.importTap(from: tapFolder)
        
        let savedTap = try #require(store.savedTap)
        
        #expect(savedTap.name == "myTap")
        #expect(store.savedFormulas.isEmpty)
        #expect(result.warnings.count == 1)
    }
    
    @Test("Does not import tap when GitHub CLI is missing")
    func importTapMissingGHCLIFails() {
        let tapFolder = MockDirectory(path: "/taps/homebrew-myTap")
        let (sut, store, _) = makeSUT(ghIsInstalled: false)
        
        #expect(throws: NnexError.self) {
            try sut.importTap(from: tapFolder)
        }
        
        #expect(store.savedTap == nil)
        #expect(store.savedFormulas.isEmpty)
    }
}


// MARK: - SUT
private extension HomebrewTapManagerTests {
    func makeSUT(storeThrows: Bool = false, gitThrows: Bool = false, ghIsInstalled: Bool = true, remoteURL: String = "remotePath") -> (sut: HomebrewTapManager, store: MockStore, gitHandler: MockGitHandler) {
        let shell = MockShell()
        let store = MockStore(throwError: storeThrows)
        let gitHandler = MockGitHandler(remoteURL: remoteURL, ghIsInstalled: ghIsInstalled, throwError: gitThrows)
        let sut = HomebrewTapManager(shell: shell, store: store, gitHandler: gitHandler)
        
        return (sut, store, gitHandler)
    }
}


// MARK: - Mocks
private extension HomebrewTapManagerTests {
    final class MockStore: HomebrewTapStore {
        private let throwError: Bool
        
        private(set) var savedPath: String?
        private(set) var savedTap: HomebrewTap?
        private(set) var savedFormulas: [HomebrewFormula] = []
        
        init(throwError: Bool = false) {
            self.throwError = throwError
        }
        
        func saveTapListFolderPath(path: String) {
            savedPath = path
        }
        
        func saveNewTap(_ tap: HomebrewTap, formulas: [HomebrewFormula]) throws {
            if throwError { throw NSError(domain: "Test", code: 0) }
            
            savedTap = tap
            savedFormulas = formulas
        }
    }
}
