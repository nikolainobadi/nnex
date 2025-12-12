//
//  HomebrewTapManagerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import Testing
import Foundation
import NnexSharedTestHelpers
@testable import NnexKit

final class HomebrewTapManagerTests {
    @Test("Starting values empty")
    func emptyStartingValues() {
        let (_, store) = makeSUT()
        
        #expect(store.savedTap == nil)
        #expect(store.savedPath == nil)
    }
}


// MARK: - SUT
private extension HomebrewTapManagerTests {
    func makeSUT(throwError: Bool = false) -> (sut: HomebrewTapManager, store: MockStore) {
        let store = MockStore(throwError: throwError)
        let gitHandler = MockGitHandler()
        let sut = HomebrewTapManager(store: store, gitHandler: gitHandler)
        
        return (sut, store)
    }
}


// MARK: - Mocks
private extension HomebrewTapManagerTests {
    final class MockStore: HomebrewTapStore {
        private let throwError: Bool
        
        private(set) var savedPath: String?
        private(set) var savedTap: HomebrewTap?
        
        init(throwError: Bool) {
            self.throwError = throwError
        }
        
        func saveTapListFolderPath(path: String) {
            savedPath = path
        }
        
        func saveNewTap(_ tap: HomebrewTap) throws {
            if throwError { throw NSError(domain: "Test", code: 0) }
            
            savedTap = tap
        }
    }
}
