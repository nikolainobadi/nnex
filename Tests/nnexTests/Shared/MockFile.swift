//
//  MockFile.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/9/25.
//

@testable import nnex

struct MockFile: FileProtocol {
    let path: String
    private let content: String
    
    init(path: String, content: String) {
        self.path = path
        self.content = content
    }
    
    func readAsString() throws -> String {
        return content
    }
}
