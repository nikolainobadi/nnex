//
//  Export.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import ArgumentParser

extension Nnex {
    struct Export: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Export notarized applications for distribution.",
            subcommands: [MacOS.self]
        )
    }
}