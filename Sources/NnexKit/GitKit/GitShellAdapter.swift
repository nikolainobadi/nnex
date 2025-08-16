//
//  GitShellAdapter.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import GitShellKit

/// Adapter for executing Git shell commands.
struct GitShellAdapter {
    private let shell: Shell

    /// Initializes a new instance of GitShellAdapter with the specified shell.
    /// - Parameter shell: The shell used to execute commands.
    init(shell: Shell) {
        self.shell = shell
    }
}


// MARK: - GitShell
extension GitShellAdapter: GitShell {
    /// Runs a shell command and returns the output.
    /// - Parameter command: The shell command to execute.
    /// - Returns: The output of the executed command.
    func runWithOutput(_ command: String) throws -> String {
        return try shell.run(command)
    }
}
