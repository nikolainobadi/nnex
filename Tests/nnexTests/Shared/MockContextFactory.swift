//
//  MockContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import SwiftData
import Foundation
import NnexSharedTestHelpers
@testable import nnex

final class MockContextFactory {
    private let selectedItemIndex: Int
    private let tapListFolderPath: String?
    private let runResults: [String]
    private let inputResponses: [String]
    private let permissionResponses: [Bool]
    private let gitHandler: MockGitHandler
    private var shell: MockShell?
    private var picker: MockPicker?
    private var context: NnexContext?
    
    init(tapListFolderPath: String? = nil, runResults: [String] = [], selectedItemIndex: Int = 0, inputResponses: [String] = [], permissionResponses: [Bool] = [], gitHandler: MockGitHandler = .init(), shell: MockShell? = nil) {
        self.tapListFolderPath = tapListFolderPath
        self.runResults = runResults
        self.inputResponses = inputResponses
        self.permissionResponses = permissionResponses
        self.gitHandler = gitHandler
        self.selectedItemIndex = selectedItemIndex
        self.shell = shell
    }
}


// MARK: - Factory
extension MockContextFactory: ContextFactory {
    func makeShell() -> Shell {
        if let shell {
            return shell
        }
        
        let newShell = MockShell(runResults: runResults)
        shell = newShell
        return newShell
    }
    
    func makePicker() -> Picker {
        if let picker {
            return picker
        }
        
        let newPicker = MockPicker(selectedItemIndex: selectedItemIndex, inputResponses: inputResponses, permissionResponses: permissionResponses)
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
}

// MARK: - Private
private extension MockContextFactory {
    func makeDefaults() -> UserDefaults {
        let testSuiteName = "testSuiteDefaults"
        let userDefaults = UserDefaults(suiteName: testSuiteName)!
        userDefaults.removePersistentDomain(forName: testSuiteName)
        
        return userDefaults
    }
}
