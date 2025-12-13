//
//  FormulaPublishControllerTests.swift
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

final class FormulaPublishControllerTests {
    @Test("Publishes existing formula and commits with provided message")
    func publishExistingFormulaCommits() throws {
        let tapPath = "/taps/homebrew-tool"
        let formulaFolder = MockDirectory(path: tapPath.appendingPathComponent("Formula"), containedFiles: ["tool.rb"])
        let tapDirectory = MockDirectory(path: tapPath, subdirectories: [formulaFolder])
        let fileSystem = MockFileSystem(directoryMap: [tapPath: tapDirectory])
        let formula = makeFormula(name: "tool", tapPath: tapPath, localProjectPath: "")
        let tap = HomebrewTap(name: "Tap", localPath: tapPath, remotePath: "", formulas: [formula])
        let info = makePublishInfo(assetURLs: ["https://example.com/tool.tar.gz"])
        let gitHandler = MockGitHandler()
        let (sut, store, git, _, _, project) = makeSUT(
            taps: [tap],
            fileSystem: fileSystem,
            gitHandler: gitHandler
        )
        
        try sut.publishFormula(projectFolder: project, info: info, commitMessage: "update formula")
        
        #expect(store.updatedFormula?.localProjectPath == project.path)
        #expect(formulaFolder.containsFile(named: "tool.rb"))
        #expect(git.message == "update formula")
    }
    
    @Test("Creates new formula when none exist for project")
    func publishCreatesNewFormulaWhenMissing() throws {
        let tap1 = HomebrewTap(name: "First", localPath: "/taps/first", remotePath: "", formulas: [])
        let tap2Path = "/taps/second"
        let tap2Directory = MockDirectory(path: tap2Path)
        let tap2 = HomebrewTap(name: "Second", localPath: tap2Path, remotePath: "", formulas: [])
        let project = MockDirectory(path: "/projects/tool", containedFiles: ["LICENSE"])
        project.fileContents["LICENSE"] = "MIT License"
        let fileSystem = MockFileSystem(directoryMap: ["": tap2Directory, tap2Path: tap2Directory])
        let picker = FormulaPublishControllerTests.makePicker(inputResults: ["A tool"], selectionIndex: 1, permissionResults: [true, false])
        let gitHandler = MockGitHandler(remoteURL: "https://example.com/repo.git")
        let info = makePublishInfo(assetURLs: ["https://example.com/tool.tar.gz"])
        let (sut, store, git, fs, _, projectDir) = makeSUT(
            taps: [tap1, tap2],
            picker: picker,
            fileSystem: fileSystem,
            gitHandler: gitHandler,
            projectFolder: project
        )
        
        try sut.publishFormula(projectFolder: projectDir, info: info, commitMessage: nil)
        
        let savedFormula = try #require(store.savedFormula)
        #expect(savedFormula.name == project.name)
        #expect(savedFormula.details == "A tool")
        #expect(savedFormula.homepage == "https://example.com/repo.git")
        #expect(savedFormula.license == "MIT")
        #expect(savedFormula.testCommand == nil) // skipTests true
        #expect(store.savedTap?.name == tap2.name)
        #expect(fs.capturedPaths.contains(""))
        #expect(git.message == nil) // commit skipped when permission denied
    }
    
    @Test("Throws when single archive is missing URL")
    func publishThrowsWhenAssetMissing() {
        let tapPath = "/taps/homebrew-tool"
        let formulaFolder = MockDirectory(path: tapPath.appendingPathComponent("Formula"))
        let tapDirectory = MockDirectory(path: tapPath, subdirectories: [formulaFolder])
        let fileSystem = MockFileSystem(directoryMap: [tapPath: tapDirectory])
        let formula = makeFormula(name: "tool", tapPath: tapPath, localProjectPath: "/projects/tool")
        let tap = HomebrewTap(name: "Tap", localPath: tapPath, remotePath: "", formulas: [formula])
        let archives = [ArchivedBinary(originalPath: "/tmp/tool", archivePath: "/tmp/tool.tar.gz", sha256: "abc123")]
        let info = FormulaPublishInfo(version: "1.0.0", installName: "tool", assetURLs: [], archives: archives)
        let (sut, store, git, _, _, project) = makeSUT(taps: [tap], fileSystem: fileSystem)
        
        #expect(throws: NnexError.missingSha256) {
            try sut.publishFormula(projectFolder: project, info: info, commitMessage: nil)
        }
        
        #expect(store.updatedFormula == nil)
        #expect(git.message == nil)
    }
    
    @Test("Includes both architecture URLs when building formula content")
    func publishUsesBothArchitectures() throws {
        let tapPath = "/taps/homebrew-tool"
        let formulaFolder = MockDirectory(path: tapPath.appendingPathComponent("Formula"))
        let tapDirectory = MockDirectory(path: tapPath, subdirectories: [formulaFolder])
        let fileSystem = MockFileSystem(directoryMap: [tapPath: tapDirectory])
        let formula = makeFormula(name: "tool", tapPath: tapPath, localProjectPath: "/projects/tool")
        let tap = HomebrewTap(name: "Tap", localPath: tapPath, remotePath: "", formulas: [formula])
        let armArchive = ArchivedBinary(originalPath: "/tmp/.build/arm64-apple-macosx/release/tool", archivePath: "/tmp/tool-arm64.tar.gz", sha256: "arm")
        let intelArchive = ArchivedBinary(originalPath: "/tmp/.build/x86_64-apple-macosx/release/tool", archivePath: "/tmp/tool-x86_64.tar.gz", sha256: "intel")
        let info = FormulaPublishInfo(version: "1.0.0", installName: "tool", assetURLs: ["arm-url", "intel-url"], archives: [armArchive, intelArchive])
        let (sut, _, _, _, _, project) = makeSUT(taps: [tap], fileSystem: fileSystem)
        
        try sut.publishFormula(projectFolder: project, info: info, commitMessage: nil)
        
        let content = try formulaFolder.readFile(named: "tool.rb")
        #expect(content.contains("arm-url"))
        #expect(content.contains("intel-url"))
        #expect(content.contains("sha256 \"arm\""))
        #expect(content.contains("sha256 \"intel\""))
    }
}


// MARK: - SUT
private extension FormulaPublishControllerTests {
    func makeSUT(
        taps: [HomebrewTap],
        picker: MockSwiftPicker = FormulaPublishControllerTests.makePicker(),
        fileSystem: MockFileSystem = MockFileSystem(),
        gitHandler: MockGitHandler = MockGitHandler(),
        projectFolder: MockDirectory = MockDirectory(path: "/projects/tool")
    ) -> (sut: FormulaPublishController, store: MockPublishStore, gitHandler: MockGitHandler, fileSystem: MockFileSystem, picker: MockSwiftPicker, project: MockDirectory) {
        let store = MockPublishStore(taps: taps)
        let sut = FormulaPublishController(picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, store: store)
        
        return (sut, store, gitHandler, fileSystem, picker, projectFolder)
    }
    
    func makeFormula(name: String, tapPath: String, localProjectPath: String) -> HomebrewFormula {
        .init(
            name: name,
            details: "details",
            homepage: "homepage",
            license: "license",
            localProjectPath: localProjectPath,
            uploadType: .tarball,
            testCommand: nil,
            extraBuildArgs: [],
            tapLocalPath: tapPath
        )
    }
    
    func makePublishInfo(assetURLs: [String]) -> FormulaPublishInfo {
        let archive = ArchivedBinary(originalPath: "/tmp/tool", archivePath: "/tmp/tool.tar.gz", sha256: "abc123")
        return FormulaPublishInfo(version: "1.0.0", installName: "tool", assetURLs: assetURLs, archives: [archive])
    }
}


// MARK: - Mocks
private extension FormulaPublishControllerTests {
    final class MockPublishStore: PublishInfoStore {
        private let taps: [HomebrewTap]
        
        private(set) var updatedFormula: HomebrewFormula?
        private(set) var savedFormula: HomebrewFormula?
        private(set) var savedTap: HomebrewTap?
        
        init(taps: [HomebrewTap]) {
            self.taps = taps
        }
        
        func loadTaps() throws -> [HomebrewTap] {
            return taps
        }
        
        func updateFormula(_ formula: HomebrewFormula) throws {
            updatedFormula = formula
        }
        
        func saveNewFormula(_ formula: HomebrewFormula, in tap: HomebrewTap) throws {
            savedFormula = formula
            savedTap = tap
        }
    }
    
    static func makePicker(inputResults: [String] = [], selectionIndex: Int = 0, permissionResults: [Bool] = []) -> MockSwiftPicker {
        MockSwiftPicker(
            inputResult: .init(type: .ordered(inputResults)),
            permissionResult: .init(type: .ordered(permissionResults)),
            selectionResult: .init(defaultSingle: .index(selectionIndex))
        )
    }
}
