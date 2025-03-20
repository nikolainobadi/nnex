//
//  MockContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import SwiftData
import Foundation
@testable import nnex

final class MockContextFactory {
    private let runResults: [String]
    private let inputResponses: [String]
    private var shell: MockShell?
    private var context: SharedContext?
    
    init(runResults: [String] = [], inputResponses: [String] = []) {
        self.runResults = runResults
        self.inputResponses = inputResponses
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
        return MockPicker(inputResponses: inputResponses)
    }
    
    func makeFolderLoader() -> FolderLoader {
        return MockFolderLoader()
    }
    
    func makeContext() throws -> SharedContext {
        if let context {
            return context
        }
        
        let defaults = makeDefaults()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let context = try SharedContext(config: config, defaults: defaults)
        
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

struct TestShell: Shell {
    func run(_ command: String) throws -> String {
        return "" // TODO: -
    }
    
    func runAndPrint(_ command: String) throws {
        // TODO: -
    }
}
