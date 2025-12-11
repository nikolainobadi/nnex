//
//  Brew.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import ArgumentParser

extension Nnex {
    struct Brew: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Commands to manage Homebrew distribution",
            subcommands: [
                Publish.self,
                ImportTap.self,
                CreateTap.self,
                TapList.self,
                Untap.self,
                RemoveFormula.self
            ]
        )
    }
}
