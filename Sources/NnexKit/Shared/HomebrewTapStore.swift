//
//  HomebrewTapStore.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/11/25.
//

public protocol HomebrewTapStore {
    func loadTaps() throws -> [HomebrewTap]
    func updateFormula(_ formula: HomebrewFormula) throws
    func saveNewFormula(_ formula: HomebrewFormula, in tap: HomebrewTap) throws
}
