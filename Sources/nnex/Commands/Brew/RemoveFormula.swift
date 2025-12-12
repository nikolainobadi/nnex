//
//  RemoveFormula.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/31/25.
//

import NnexKit
import ArgumentParser

extension Nnex.Brew {
    struct RemoveFormula: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Removes a formula from an existing Homebrew tap")
        
        func run() throws {
            try Nnex.makeHomebrewFormulaController().removeFormula()
        }
    }
}
