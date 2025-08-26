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
    @discardableResult
    static func testRun(contextFactory: MockContextFactory? = nil, args: [String]? = []) throws -> String {
        let factory = contextFactory ?? MockContextFactory()
        self.contextFactory = factory
        
        return try captureOutput(factory: factory, args: args)
    }
}


// MARK: - Helper Methods
fileprivate extension Nnex {
    static func captureOutput(factory: MockContextFactory? = nil, args: [String]?) throws -> String {
        let pipe = Pipe()
        let readHandle = pipe.fileHandleForReading
        let writeHandle = pipe.fileHandleForWriting

        let originalStdout = dup(STDOUT_FILENO) // Save original stdout
        dup2(writeHandle.fileDescriptor, STDOUT_FILENO) // Redirect stdout to pipe
        
        var command = try Self.parseAsRoot(args)
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
