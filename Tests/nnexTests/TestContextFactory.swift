//
//  TestContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import SwiftData
import Foundation
@testable import nnex

final class TestContextFactory {
    private let inputProvider: (InputType) -> String
    private let permissionProvider: (PermissionType) -> Bool
    private var context: SharedContext?
    
    init(inputProvider: @escaping (InputType) -> String = { _ in "" }, permissionProvider: @escaping (PermissionType) -> Bool = { _ in false }) {
        self.inputProvider = inputProvider
        self.permissionProvider = permissionProvider
    }
}


// MARK: - Factory
extension TestContextFactory: ContextFactory {
    func makeShell() -> Shell {
        return TestShell()
    }
    
    func makePicker() -> Picker {
        return TestPicker(inputProvider: inputProvider, permissionProvider: permissionProvider)
    }
    
    func makeFolderLoader() -> FolderLoader {
        return TestFolderLoader()
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
private extension TestContextFactory {
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
