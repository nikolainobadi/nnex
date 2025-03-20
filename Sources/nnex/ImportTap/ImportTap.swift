//
//  ImportTap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import SwiftShell
import Foundation
import ArgumentParser

extension Nnex.Brew {
    struct ImportTap: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Select an existing homebrew tap folder on your computer to register."
        )
        
        @Option(name: .shortAndLong, help: "")
        var path: String?
        
        func run() throws {
            let context = try Nnex.makeContext()
            let path = try path ?? Nnex.makePicker().getRequiredInput(.importTapPath)
            let folder = try Folder(path: path)
            let tapName = folder.name.removingHomebrewPrefix
            let formulaFiles = folder.files.filter({ $0.extension == "rb" })
            let remotePath = Nnex.makeRemoteRepoLoader().getGitHubURL(path: folder.path)
            let tap = SwiftDataTap(name: tapName, localPath: folder.path, remotePath: remotePath)
            
            var formulas: [SwiftDataFormula] = []
            
            for file in formulaFiles {
                let output = SwiftShell.run(bash: "brew info --json=v2 \(file.path)").stdout
                if let data = output.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    let rootObject = try decoder.decode([String: [BrewFormula]].self, from: data)
                    
                    if let brewFormula = rootObject["formulae"]?.first {
                        formulas.append(.init(from: brewFormula))
                        print("decoded \(brewFormula.name), added to tap.")
                    } else {
                        print("could not decode formula")
                    }
                }
            }
            
            try context.saveNewTap(tap, formulas: formulas)
        }
    }
}


// MARK: - Dependencies
protocol RemoteRepoHandler {
    func getGitHubURL(path: String?) -> String
}
