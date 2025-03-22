//
//  DefaultShell.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import SwiftShell

public struct DefaultShell {
    public init() { }
}

extension DefaultShell: Shell {
    public func runAndPrint(_ command: String) throws {
        try SwiftShell.runAndPrint(bash: command)
    }
    
    public func run(_ command: String) throws -> String {
        let output = SwiftShell.run(bash: command)
        
        guard output.succeeded else {
            throw NnexError.shellCommandFailed
        }
        
        return output.stdout.trimmingCharacters(in: .whitespaces)
    }
}
