//
//  HomebrewTapStoreAdapter.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

public struct HomebrewTapStoreAdapter {
    private let context: NnexContext
    
    public init(context: NnexContext) {
        self.context = context
    }
}


// MARK: - HomebrewTapStore
extension HomebrewTapStoreAdapter: HomebrewTapStore {
    public func saveTapListFolderPath(path: String) {
        context.saveTapListFolderPath(path: path)
    }
    
    public func saveNewTap(_ tap: HomebrewTap, formulas: [HomebrewFormula]) throws {
        let swiftDataTap = HomebrewTapMapper.toSwiftData(tap)
        let swiftDataFormulas = formulas.map(HomebrewFormulaMapper.toSwiftData)
        
        try context.saveNewTap(swiftDataTap, formulas: swiftDataFormulas)
    }
}
