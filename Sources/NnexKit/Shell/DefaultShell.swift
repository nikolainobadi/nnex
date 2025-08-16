//
//  DefaultShell.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import SwiftShell

/// Default implementation of the Shell protocol, using SwiftShell to execute commands.
public struct DefaultShell {
    /// Initializes a new instance of DefaultShell.
    public init() {}
}


// MARK: - Shell
extension DefaultShell: Shell {
    /// Runs a shell command and prints its output directly to the console.
    /// - Parameter command: The shell command to execute.
    /// - Throws: An error if the command fails.
    public func runAndPrint(_ command: String) throws {
        try SwiftShell.runAndPrint(bash: command)
    }

    /// Runs a shell command and returns its output as a string.
    /// - Parameter command: The shell command to execute.
    /// - Returns: The output from the executed command.
    /// - Throws: An error if the command fails or the command output is unsuccessful.
    public func run(_ command: String) throws -> String {
        let output = SwiftShell.run(bash: command)

        guard output.succeeded else {
            throw NnexError.shellCommandFailed
        }

        return output.stdout.trimmingCharacters(in: .whitespaces)
    }
}
