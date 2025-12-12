//
//  MockHomebrewTapStore.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/11/25.
//

import NnexKit
@testable import nnex

final class MockHomebrewTapStore: PublishInfoStore {
    private let tapsToLoad: [HomebrewTap]
    
    private(set) var formulaToUpdate: HomebrewFormula?
    private(set) var newFormulaData: (formula: HomebrewFormula, tap: HomebrewTap)?
    
    init(taps: [HomebrewTap]) {
        self.tapsToLoad = taps
    }
    
    func loadTaps() throws -> [HomebrewTap] {
        return tapsToLoad
    }
    
    func updateFormula(_ formula: HomebrewFormula) throws {
        formulaToUpdate = formula
    }
    
    func saveNewFormula(_ formula: HomebrewFormula, in tap: HomebrewTap) throws {
        newFormulaData = (formula, tap)
    }
}
