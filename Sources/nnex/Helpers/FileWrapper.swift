//
//  FileWrapper.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/20/25.
//

import Files

struct FileWrapper: FileProtocol {
    private let file: File
    
    init(file: File) {
        self.file = file
    }
    
    var path: String { file.path }
    
    func readAsString() throws -> String {
        try file.readAsString()
    }
}
