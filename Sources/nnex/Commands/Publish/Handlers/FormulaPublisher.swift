//
//  FormulaPublisher.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files

struct FormulaPublisher {
    private let picker: Picker
    private let message: String?
    private let gitHandler: GitHandler
    
    init(picker: Picker, message: String?, gitHandler: GitHandler) {
        self.picker = picker
        self.message = message
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
        
        if let message = try getMessage(message: message) {
            try gitHandler.commitAndPush(message: message, path: tap.localPath)
        }
    }
}


// MARK: - Private Methods
private extension FormulaPublisher {
    func getMessage(message: String?) throws -> String? {
        if let message {
            return message
        }
        
        guard picker.getPermission(prompt: "Would you like to commit and push the tap to GitHub?") else {
            return nil
        }
        
        return try picker.getRequiredInput(prompt: "Enter your commit message.")
    }
}
