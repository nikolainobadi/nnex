//
//  Archive.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import ArgumentParser

extension Nnex {
    struct Archive: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Archive applications for different platforms.",
            subcommands: [
                MacOS.self,
                IOS.self
            ]
        )
    }
}
