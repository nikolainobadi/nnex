//
//  FormulaPublisher.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files

struct FormulaPublisher {
    private let shell: Shell
    
    init(shell: Shell) {
        self.shell = shell
    }
}


// MARK: - Publish
extension FormulaPublisher {
    func publishFormula(_ content: String, formulaName: String, tap: SwiftDataTap) throws {
        let fileName = "\(formulaName).rb"
        let tapFolder = try Folder(path: tap.localPath)
        
        if tapFolder.containsFile(named: fileName) {
            print("\nDeleting old \(formulaName) formula to replace with new formula...")
            try tapFolder.file(named: fileName).delete()
        }
        
        let newFile = try tapFolder.createFile(named: fileName)
        try newFile.write(content)
        
        print("\nSuccessfully created formula at \(newFile.path)")
        
        // TODO: - commit changes to tap folder and push to github
        // maybe I should ask permission and allow a flag to be passed in to 'force' the push or something
    }
}
