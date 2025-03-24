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
            usage: "",
            subcommands: [ImportTap.self, CreateTap.self, TapList.self, Publish.self, Untap.self]
        )
    }
}
