//
//  MockContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import SwiftData
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
    private var trashHandler: MockTrashHandler?
    
    init(
        tapListFolderPath: String? = nil,
        runResults: [String] = [],
        commandResults: [String: String] = [:],
        selectedItemIndex: Int = 0,
        selectedItemIndices: [Int] = [],
        inputResponses: [String] = [],
        permissionResponses: [Bool] = [],
        gitHandler: MockGitHandler = .init(),
        shell: MockShell? = nil,
        trashHandler: MockTrashHandler? = nil
    ) {
        self.tapListFolderPath = tapListFolderPath
        self.runResults = runResults
        self.commandResults = commandResults
        self.inputResponses = inputResponses
        self.permissionResponses = permissionResponses
        self.gitHandler = gitHandler
        self.selectedItemIndex = selectedItemIndex
        self.selectedItemIndices = selectedItemIndices
        self.shell = shell
        self.trashHandler = trashHandler
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
        
        let defaults = makeDefaults()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let context = try NnexContext(appGroupId: "not needed", config: config, defaults: defaults)
        
        if let tapListFolderPath {
            context.saveTapListFolderPath(path: tapListFolderPath)
        }
        
        self.context = context
        
        return context
    }
    
    func makeProjectDetector() -> any ProjectDetector {
        return DefaultProjectDetector(shell: makeShell())
    }
    
    func makeMacOSArchiveBuilder() -> any ArchiveBuilder {
        return DefaultMacOSArchiveBuilder(shell: makeShell())
    }
    
    func makeNotarizeHandler() -> any NotarizeHandler {
        return DefaultNotarizeHandler(shell: makeShell(), picker: makePicker())
    }
    
    func makeExportHandler() -> any ExportHandler {
        return DefaultExportHandler(shell: makeShell())
    }
    
    func makeTrashHandler() -> any TrashHandler {
        if let trashHandler {
            return trashHandler
        }
        
        let newTrashHandler = MockTrashHandler()
        trashHandler = newTrashHandler
        return newTrashHandler
    }
}

// MARK: - Private
private extension MockContextFactory {
    func makeDefaults() -> UserDefaults {
        let testSuiteName = "testSuiteDefaults_\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: testSuiteName)!
        userDefaults.removePersistentDomain(forName: testSuiteName)
        
        return userDefaults
    }
}
