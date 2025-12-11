//
//  MockDirectoryBrowser.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/11/25.
//

import NnexKit
import Foundation
@testable import nnex

final class MockDirectoryBrowser: DirectoryBrowser {
    private let filePathToReturn: String?
    private let directoryToReturn: (any Directory)?
    
    init(filePathToReturn: String?, directoryToReturn: (any Directory)?) {
        self.filePathToReturn = filePathToReturn
        self.directoryToReturn = directoryToReturn
    }
    
    func browseForFile(prompt: String) throws -> String {
        guard let filePathToReturn else {
            throw NSError(domain: "Test", code: 0)
        }
        
        return filePathToReturn
    }
    
    func browseForDirectory(prompt: String) throws -> any Directory {
        guard let directoryToReturn else {
            throw NSError(domain: "Test", code: 0)
        }
        
        return directoryToReturn
    }
}
