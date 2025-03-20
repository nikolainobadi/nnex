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
    private let inputResponses: [String]
    private var context: SharedContext?
    
    init(inputResponses: [String] = []) {
        self.inputResponses = inputResponses
    }
}


// MARK: - Factory
extension MockContextFactory: ContextFactory {
    func makeShell() -> Shell {
        return MockShell()
    }
    
    func makePicker() -> Picker {
        return MockPicker(inputResponses: inputResponses)
    }
    
    func makeFolderLoader() -> FolderLoader {
        return MockFolderLoader()
    }
    
    func makeRemoteRepoLoader() -> RemoteRepoHandler {
        return TestRepoHandler()
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

struct TestRepoHandler: RemoteRepoHandler {
    func getGitHubURL(path: String?) -> String {
        return "" // TODO: -
    }
    
    func getPreviousVersionNumber(path: String?) -> String? {
        return "" // TODO: -
    }
}
