//
//  HomebrewFormulaService.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/31/25.
//

public protocol HomebrewFormulaService {
    func loadFormulas() throws -> [SwiftDataHomebrewFormula]
    func deleteFormula(_ formula: SwiftDataHomebrewFormula) throws
}
