//
//  FormulaPublisher.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files

public struct FormulaPublisher {
    private let gitHandler: GitHandler
    
    public init(gitHandler: GitHandler) {
        self.gitHandler = gitHandler
    }
}


// MARK: - Publish
public extension FormulaPublisher {
    func publishFormula(_ content: String, formulaName: String, commitMessage: String?, tapFolderPath: String) throws -> String {
        let fileName = "\(formulaName).rb"
        let tapFolder = try Folder(path: tapFolderPath)
        
        if tapFolder.containsFile(named: fileName) {
            try tapFolder.file(named: fileName).delete()
        }
        
        let newFile = try tapFolder.createFile(named: fileName)
        try newFile.write(content)
        
        if let commitMessage {
            try gitHandler.commitAndPush(message: commitMessage, path: tapFolderPath)
        }
        
        return newFile.path
    }
}
