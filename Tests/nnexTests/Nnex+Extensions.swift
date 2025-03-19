//
//  Nnex+Extensions.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Foundation
import ArgumentParser
@testable import nnex

extension Nnex {
    static func captureOutput(contextFactory: TestContextFactory? = nil, args: [String]? = []) throws -> String {
        self.contextFactory = contextFactory ?? TestContextFactory()
        
        return try captureOutput(args)
    }
}


// MARK: - Helper Methods
fileprivate extension ParsableCommand {
    static func captureOutput(_ arguments: [String]?) throws -> String {
        let pipe = Pipe()
        let readHandle = pipe.fileHandleForReading
        let writeHandle = pipe.fileHandleForWriting

        let originalStdout = dup(STDOUT_FILENO) // Save original stdout
        dup2(writeHandle.fileDescriptor, STDOUT_FILENO) // Redirect stdout to pipe
        
        var command = try Self.parseAsRoot(arguments)
        try command.run()
        
        fflush(stdout) // Ensure all output is flushed
        dup2(originalStdout, STDOUT_FILENO) // Restore original stdout
        close(originalStdout) // Close saved stdout
        writeHandle.closeFile() // Close the writing end of the pipe

        let data = readHandle.readDataToEndOfFile() // Read the output
        readHandle.closeFile() // Close reading end

        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
