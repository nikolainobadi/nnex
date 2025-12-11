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
            let picker = Nnex.makePicker()
            let fileSystem = Nnex.makeFileSystem()
            let context = try Nnex.makeContext()
            let formulas = try context.loadFormulas()
            let selection = try picker.requiredSingleSelection("Select a formula to remove", items: formulas)

            if let tap = selection.tap,
               let tapDirectory = try? fileSystem.directory(at: tap.localPath),
               let formulaDirectory = try? tapDirectory.subdirectory(named: "Formula") {
                
                let formulaFileName = "\(selection.name).rb"
                if formulaDirectory.containsFile(named: formulaFileName),
                   picker.getPermission(prompt: "Would you also like to delete the formula file for \(selection.name)?") {
                    try formulaDirectory.deleteFile(named: formulaFileName)
                }
            }
            
            try context.deleteFormula(selection)
        }
    }
}
