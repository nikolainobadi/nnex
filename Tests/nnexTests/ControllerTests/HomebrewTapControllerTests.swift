//
//  HomebrewTapControllerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import NnexKit
import Testing
import Foundation
import NnShellTesting
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex

final class HomebrewTapControllerTests {
    @Test("Starting values empty")
    func emptyStartingValues() {
        let (_, service) = makeSUT()
        
        #expect(service.savedPath == nil)
        #expect(service.savedTapData == nil)
    }
}


// MARK: - SUT
private extension HomebrewTapControllerTests {
    func makeSUT(inputResults: [String] = [], directoryToLoad: MockDirectory? = nil, browsedDirectory: MockDirectory? = nil, selectionIndex: Int = 0, fileSystem: MockFileSystem? = nil, throwError: Bool = false) -> (sut: HomebrewTapController, service: MockService) {
        let shell = MockShell()
        let picker = MockSwiftPicker(inputResult: .init(type: .ordered(inputResults)), selectionResult: .init(defaultSingle: .index(selectionIndex)))
        let fileSystem = fileSystem ?? MockFileSystem(directoryToLoad: directoryToLoad)
        let folderBrowser = MockDirectoryBrowser(filePathToReturn: nil, directoryToReturn: browsedDirectory)
        let service = MockService(throwError: throwError)
        let sut = HomebrewTapController(shell: shell, picker: picker, fileSystem: fileSystem, service: service, folderBrowser: folderBrowser)
        
        return (sut, service)
    }
}


// MARK: - Mocks
private extension HomebrewTapControllerTests {
    final class MockService: HomebrewTapService {
        private let throwError: Bool
        
        private(set) var savedPath: String?
        private(set) var savedTapData: (name: String, details: String, parent: any Directory, isPrivate: Bool)?
        
        init(throwError: Bool) {
            self.throwError = throwError
        }
        
        func saveTapListFolderPath(path: String) {
            savedPath = path
        }
        
        func createNewTap(named name: String, details: String, in parentFolder: any Directory, isPrivate: Bool) throws {
            if throwError { throw NSError(domain: "Test", code: 0) }
            
            savedTapData = (name, details, parentFolder, isPrivate)
        }
    }
}
