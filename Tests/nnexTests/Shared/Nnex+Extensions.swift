////
////  Nnex+Extensions.swift
////  nnex
////
////  Created by Nikolai Nobadi on 3/19/25.
////
//
//import Foundation
//import ArgumentParser
//@testable import nnex
//
//extension Nnex {
//    @discardableResult
//    static func testRun(contextFactory: MockContextFactory? = nil, args: [String]? = []) throws -> String {
//        self.contextFactory = contextFactory ?? MockContextFactory()
//        
//        return try captureOutput(args: args)
//    }
//}
//
//
//// MARK: - Helper Methods
//private extension Nnex {
//    /// Captures stdout from invoking the command so it can be asserted in tests.
//    static func captureOutput(args: [String]?) throws -> String {
//        let pipe = Pipe()
//        let readHandle = pipe.fileHandleForReading
//        let writeHandle = pipe.fileHandleForWriting
//
//        let originalStdout = dup(STDOUT_FILENO)
//        dup2(writeHandle.fileDescriptor, STDOUT_FILENO)
//
//        do {
//            var command = try Self.parseAsRoot(args)
//            try command.run()
//        } catch {
//            // Restore stdout before rethrowing
//            fflush(stdout)
//            dup2(originalStdout, STDOUT_FILENO)
//            close(originalStdout)
//            writeHandle.closeFile()
//            readHandle.closeFile()
//            throw error
//        }
//
//        fflush(stdout)
//        dup2(originalStdout, STDOUT_FILENO)
//        close(originalStdout)
//        writeHandle.closeFile()
//
//        let data = readHandle.readDataToEndOfFile()
//        readHandle.closeFile()
//
//        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
//    }
//}
