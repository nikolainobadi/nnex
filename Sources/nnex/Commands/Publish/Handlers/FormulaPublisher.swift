//
//  FormulaPublisher.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files
import NnexKit

struct FormulaPublisher {
    private let gitHandler: GitHandler
    
    init(gitHandler: GitHandler) {
        self.gitHandler = gitHandler
    }
}


// MARK: - Publish
extension FormulaPublisher {
    func publishFormula(_ content: String, formulaName: String, commitMessage: String?, tap: SwiftDataTap) throws {
        let fileName = "\(formulaName).rb"
        let tapFolder = try Folder(path: tap.localPath)
        
        if tapFolder.containsFile(named: fileName) {
            print("\nDeleting old \(formulaName) formula to replace with new formula...")
            try tapFolder.file(named: fileName).delete()
        }
        
        let newFile = try tapFolder.createFile(named: fileName)
        try newFile.write(content)
        
        print("\nSuccessfully created formula at \(newFile.path)")
        
        if let commitMessage {
            try gitHandler.commitAndPush(message: commitMessage, path: tap.localPath)
        }
    }
}
