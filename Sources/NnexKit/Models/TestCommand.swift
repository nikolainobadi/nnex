//
//  TestCommand.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

public enum TestCommand: Sendable {
    /// Uses the default `swift test` command.
    case defaultCommand
    /// Uses a custom test command provided as a string.
    case custom(String)
}
