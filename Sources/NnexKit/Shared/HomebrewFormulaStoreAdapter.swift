//
//  HomebrewFormulaStoreAdapter.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/31/25.
//

public struct HomebrewFormulaStoreAdapter {
    private let context: NnexContext
    
    public init(context: NnexContext) {
        self.context = context
    }
}


// MARK: - HomebrewFormulaStore
extension HomebrewFormulaStoreAdapter: HomebrewFormulaStore {
    public func loadFormulas() throws -> [SwiftDataHomebrewFormula] {
        try context.loadFormulas()
    }
    
    public func deleteFormula(_ formula: SwiftDataHomebrewFormula) throws {
        try context.deleteFormula(formula)
    }
}
