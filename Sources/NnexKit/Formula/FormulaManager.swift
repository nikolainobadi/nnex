//
//  FormulaManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/14/25.
//

public struct FormulaManager {
    private let fileSystem: any FileSystem
    
    public init(fileSystem: any FileSystem) {
        self.fileSystem = fileSystem
    }
}


// MARK: - Actions
public extension FormulaManager {
    func resolveFormulaFile(formula: HomebrewFormula, tapFolder: any Directory, contents: String) throws -> String {
        let fileName = "\(formula.name).rb"
        let formulaFolder = try tapFolder.createSubfolderIfNeeded(named: "Formula")
        
        if formulaFolder.containsFile(named: fileName) {
            try formulaFolder.deleteFile(named: fileName)
        }
        
        return try formulaFolder.createFile(named: fileName, contents: contents)
    }
}
