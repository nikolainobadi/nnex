//
//  DefaultShell.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import SwiftShell

struct DefaultShell: Shell {
    func runAndPrint(_ command: String) throws {
        try SwiftShell.runAndPrint(bash: command)
    }
    
    func run(_ command: String) throws -> String {
        let output = SwiftShell.run(bash: command)
        
        guard output.succeeded else {
            throw NnexError.shellCommandFailed
        }
        
        return output.stdout.trimmingCharacters(in: .whitespaces)
    }
}


// MARK: - Dependencies
protocol Shell {
    func run(_ command: String) throws -> String
    func runAndPrint(_ command: String) throws
}
