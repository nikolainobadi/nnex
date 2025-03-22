//
//  MockShell.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import NnexKit
import Foundation
@testable import nnex

final class MockShell {
    private let shouldThrowError: Bool
    private let errorMessage = "MockShell error"
    private var runResults: [String]
    private(set) var printedCommands: [String] = []
    
    init(runResults: [String] = [], shouldThrowError: Bool = false) {
        self.runResults = runResults
        self.shouldThrowError = shouldThrowError
    }
}


// MARK: - Shell
extension MockShell: Shell {
    func run(_ command: String) throws -> String {
        printedCommands.append(command)
        if shouldThrowError {
            throw NSError(domain: "MockShell", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        return runResults.isEmpty ? "" : runResults.removeFirst()
    }

    func runAndPrint(_ command: String) throws {
        printedCommands.append(command)
        if shouldThrowError {
            throw NSError(domain: "MockShell", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
}
