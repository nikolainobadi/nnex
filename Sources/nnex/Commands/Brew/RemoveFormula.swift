//
//  RemoveFormula.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/31/25.
//

import Files
import NnexKit
import ArgumentParser

extension Nnex.Brew {
    struct RemoveFormula: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Removes a formula from an existing Homebrew tap")
        
        func run() throws {
            let picker = Nnex.makePicker()
            let context = try Nnex.makeContext()
            let formulas = try context.loadFormulas()
            let selection = try picker.requiredSingleSelection(title: "Select a formula to remove", items: formulas)
            
            if let tap = selection.tap, let tapFolder = try? Folder(path: tap.localPath), let formulaFile = try? tapFolder.file(named: "\(selection.name).rb"), picker.getPermission(prompt: "Would you also like to delete the formula file for \(selection.name)?") {
                
                try formulaFile.delete()
            }
            
            // TODO: - temporary workaround
            context.context.delete(selection)
            try context.saveChanges()
        }
    }
}
