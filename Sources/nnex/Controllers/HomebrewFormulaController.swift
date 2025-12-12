//
//  HomebrewFormulaController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/31/25.
//

import NnexKit

struct HomebrewFormulaController {
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let service: any HomebrewFormulaService
    
    init(picker: any NnexPicker, fileSystem: any FileSystem, service: any HomebrewFormulaService) {
        self.picker = picker
        self.fileSystem = fileSystem
        self.service = service
    }
}


// MARK: - Remove
extension HomebrewFormulaController {
    func removeFormula() throws {
        let formula = try selectFormula()
        
        try deleteFormulaFileIfNeeded(formula)
        try service.deleteFormula(formula)
    }
}


// MARK: - Private Helpers
private extension HomebrewFormulaController {
    func selectFormula() throws -> HomebrewFormula {
        let formulas = try service.loadFormulas()
        
        return try picker.requiredSingleSelection("Select a formula to remove", items: formulas)
    }
    
    func deleteFormulaFileIfNeeded(_ formula: HomebrewFormula) throws {
        guard !formula.tapLocalPath.isEmpty,
              let tapDirectory = try? fileSystem.directory(at: formula.tapLocalPath),
              let formulaDirectory = try? tapDirectory.subdirectory(named: "Formula") else {
            return
        }
        
        let formulaFileName = "\(formula.name).rb"
        guard formulaDirectory.containsFile(named: formulaFileName) else { return }
        
        if picker.getPermission(prompt: "Would you also like to delete the formula file for \(formula.name)?") {
            try formulaDirectory.deleteFile(named: formulaFileName)
        }
    }
}
