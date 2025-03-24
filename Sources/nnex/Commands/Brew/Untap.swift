//
//  Untap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import ArgumentParser

extension Nnex.Brew {
    struct Untap: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Unregisters an existing homebrew tap.")
        
        @Option(name: .shortAndLong, help: "The name of the Homebrew Tap to unregister")
        var name: String?
        
        func run() throws {
            let context = try Nnex.makeContext()
            let tapList = try context.loadTaps()
            
            if let name, let selection = tapList.first(where: { $0.name.lowercased() == name.lowercased() }) {
                try context.deleteTap(selection)
            } else {
                let selection = try Nnex.makePicker().requiredSingleSelection(title: "Select a tap.", items: tapList)
                
                try context.deleteTap(selection)
            }
        }
    }
}
