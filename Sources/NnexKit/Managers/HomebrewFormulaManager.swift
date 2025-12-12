//
//  HomebrewFormulaManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/31/25.
//

public struct HomebrewFormulaManager {
    private let store: any HomebrewFormulaStore
    
    public init(store: any HomebrewFormulaStore) {
        self.store = store
    }
}


// MARK: - HomebrewFormulaService
extension HomebrewFormulaManager: HomebrewFormulaService {
    public func loadFormulas() throws -> [HomebrewFormula] {
        try store.loadFormulas()
    }
    
    public func deleteFormula(_ formula: HomebrewFormula) throws {
        try store.deleteFormula(formula)
    }
}


// MARK: - Dependencies
public protocol HomebrewFormulaStore {
    func loadFormulas() throws -> [HomebrewFormula]
    func deleteFormula(_ formula: HomebrewFormula) throws
}
