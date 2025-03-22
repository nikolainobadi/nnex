//
//  FormulaPublisher.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files

struct FormulaPublisher {
    private let picker: Picker
    private let gitHandler: GitHandler
    
    init(picker: Picker, gitHandler: GitHandler) {
        self.picker = picker
        self.gitHandler = gitHandler
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
        
        if picker.getPermission(prompt: "Would you like to commit and push the tap to GitHub?") {
            let message = try picker.getRequiredInput(prompt: "Enter your commit message.")
            try gitHandler.commitAndPush(message: message, path: tap.localPath)
        }
    }
}
