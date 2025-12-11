//
//  MockContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import Foundation
import NnShellTesting
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex

final class MockContextFactory {
    private let selectedItemIndex: Int
    private let selectedItemIndices: [Int]
    private let tapListFolderPath: String?
    private let runResults: [String]
    private let commandResults: [String: String]
    private let inputResponses: [String]
    private let permissionResponses: [Bool]
    private let gitHandler: MockGitHandler
    private var shell: MockShell?
    private var picker: MockSwiftPicker?
    private var context: NnexContext?
    
    init(
        tapListFolderPath: String? = nil,
        runResults: [String] = [],
        commandResults: [String: String] = [:],
        selectedItemIndex: Int = 0,
        selectedItemIndices: [Int] = [],
        inputResponses: [String] = [],
        permissionResponses: [Bool] = [],
        gitHandler: MockGitHandler = .init(),
        shell: MockShell? = nil
    ) {
        self.shell = shell
        self.runResults = runResults
        self.gitHandler = gitHandler
        self.commandResults = commandResults
        self.inputResponses = inputResponses
        self.tapListFolderPath = tapListFolderPath
        self.selectedItemIndex = selectedItemIndex
        self.permissionResponses = permissionResponses
        self.selectedItemIndices = selectedItemIndices
    }
}


// MARK: - Factory
extension MockContextFactory: ContextFactory {
    func makeShell() -> any NnexShell {
        if let shell {
            return shell
        }
        
        let newShell: MockShell
        if !commandResults.isEmpty {
            newShell = .init(commands: commandResults.map({ .init(command: $0, output: $1) }))
        } else {
            newShell = MockShell(results: runResults)
        }
        shell = newShell
        return newShell
    }
    
    func makePicker() -> any NnexPicker {
        if let picker {
            return picker
        }
        
        let newPicker = MockSwiftPicker(
            inputResult: .init(type: .ordered(inputResponses)),
            permissionResult: .init(type: .ordered(permissionResponses)),
            selectionResult: .init(defaultSingle: .index(selectedItemIndex), singleType: .ordered(selectedItemIndices.map({ .index($0) })))
        )
        
        picker = newPicker
        return newPicker
    }
    
    func makeGitHandler() -> any GitHandler {
        return gitHandler
    }
    
    func makeContext() throws -> NnexContext {
        if let context {
            return context
        }
        
        let context = try NnexContext(userDefaultsTestSuiteName: "testSuiteDefaults_\(UUID().uuidString)")
        
        if let tapListFolderPath {
            context.saveTapListFolderPath(path: tapListFolderPath)
        }
        
        self.context = context
        
        return context
    }
    
    func makeFileSystem() -> any FileSystem {
        return DefaultFileSystem()
//        return MockFileSystem() // TODO: - may need to instantiate like picker/shell
    }
    
    func makeFolderBrowser(picker: any NnexPicker, fileSystem: any FileSystem) -> any DirectoryBrowser {
        // TODO: - change to mock when possible
        return DefaultDirectoryBrowser(picker: picker, fileSystem: fileSystem, homeDirectoryURL: FileManager.default.homeDirectoryForCurrentUser)
    }
}
