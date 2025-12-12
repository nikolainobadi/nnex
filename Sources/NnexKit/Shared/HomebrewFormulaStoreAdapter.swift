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
    public func loadFormulas() throws -> [HomebrewFormula] {
        let swiftDataFormulas = try context.loadFormulas()
        
        return swiftDataFormulas.map(HomebrewFormulaMapper.toDomain)
    }
    
    public func deleteFormula(_ formula: HomebrewFormula) throws {
        let swiftDataFormulas = try context.loadFormulas()
        
        guard let target = swiftDataFormulas.first(where: { $0.name == formula.name }) else { return }
        
        try context.deleteFormula(target)
    }
}
