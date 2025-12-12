//
//  ImportTap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import Foundation
import ArgumentParser

extension Nnex.Brew {
    struct ImportTap: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Select an existing homebrew tap folder on your computer to register.")
        
        @Option(name: .shortAndLong, help: "The local path to your Homebrew tap folder. If not provided, you will be prompted to enter it.")
        var path: String?
        
        func run() throws {
            try Nnex.makeHomebrewTapController().importTap(path: path)
        }
    }
}
