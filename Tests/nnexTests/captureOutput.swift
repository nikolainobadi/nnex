//
//  captureOutput.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Foundation

func captureOutput(_ action: () throws -> Void) throws -> String {
    let pipe = Pipe()
    let readHandle = pipe.fileHandleForReading
    let writeHandle = pipe.fileHandleForWriting

    let originalStdout = dup(STDOUT_FILENO) // Save original stdout
    dup2(writeHandle.fileDescriptor, STDOUT_FILENO) // Redirect stdout to pipe

    try action() // Run the command

    fflush(stdout) // Ensure all output is flushed
    dup2(originalStdout, STDOUT_FILENO) // Restore original stdout
    close(originalStdout) // Close saved stdout
    writeHandle.closeFile() // Close the writing end of the pipe

    let data = readHandle.readDataToEndOfFile() // Read the output
    readHandle.closeFile() // Close reading end

    return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
}
