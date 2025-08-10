//
//  MockFileSystemProvider.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/9/25.
//

@testable import nnex

final class MockFileSystemProvider: FileSystemProvider {
    private(set) var createdFileName: String = ""
    private(set) var createdFilePath: String = ""
    private let fileContent: String
    
    init(fileContent: String = "") {
        self.fileContent = fileContent
    }
    
    func createFile(in folderPath: String, named: String) throws -> FileProtocol {
        createdFileName = named
        createdFilePath = "\(folderPath)/\(named)"
        
        return MockFile(path: createdFilePath, content: fileContent)
    }
}
