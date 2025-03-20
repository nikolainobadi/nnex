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
    func makePicker() -> any Picker {
        return TestPicker(inputProvider: inputProvider, permissionProvider: permissionProvider)
    }
    
    func makeFolderLoader() -> any FolderLoader {
        return TestFolderLoader()
    }
    
    func makeBuilder() -> ProjectBuilder {
        return TestBuilder()
    }
    
    func makeRemoteRepoLoader() -> any RemoteRepoLoader {
        return TestRemoteRepoLoader()
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

struct TestBuilder: ProjectBuilder {
    func buildProject(name: String, path: String) throws -> UniversalBinaryPath {
        return "" // TODO: - 
    }
}

struct TestRemoteRepoLoader: RemoteRepoLoader {
    func getGitHubURL(path: String?) -> String {
        return "" // TODO: -
    }
}
