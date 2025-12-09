//
//  DefaultShell.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

import NnShellKit
import GitShellKit

public struct DefaultShell {
    private let shell: NnShell
    
    public init() {
        self.shell = .init()
    }
}


// MARK: - NnexShell
extension DefaultShell: NnexShell {
    public func bash(_ command: String) throws -> String {
        return try shell.bash(command)
    }
    
    public func runAndPrint(bash command: String) throws {
        try shell.runAndPrint(bash: command)
    }
}


// MARK: - GitShell
extension DefaultShell: GitShell {
    public func runWithOutput(_ command: String) throws -> String {
        return try shell.bash(command)
    }
}
