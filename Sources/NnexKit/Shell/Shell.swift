//
//  Shell.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

/// Protocol defining basic shell command operations.
public protocol Shell {
    /// Runs a shell command and returns its output as a string.
    /// - Parameter command: The shell command to execute.
    /// - Returns: The output from the executed command.
    /// - Throws: An error if the command fails.
    func run(_ command: String) throws -> String

    /// Runs a shell command and prints its output directly to the console.
    /// - Parameter command: The shell command to execute.
    /// - Throws: An error if the command fails.
    func runAndPrint(_ command: String) throws
}
