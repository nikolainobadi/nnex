//
//  TapList.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import ArgumentParser

extension Nnex.Brew {
    struct TapList: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Prints the list of registered taps.")
        
        func run() throws {
            let context = try Nnex.makeContext()
            let tapList = try context.loadTaps()
            
            if tapList.isEmpty {
                print("No saved taps")
            } else {
                print("found taps", tapList.count)
                for tap in tapList {
                    print(tap.name.underline)
                    print(" formulas: \(tap.formulas.count)")
                    print(" localPath: \(tap.localPath)")
                    print(" remotePath: \(tap.remotePath)")
                }
            }
        }
    }
}
