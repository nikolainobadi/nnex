//
//  TestFailureError.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

import Foundation

public struct TestFailureError: Error, LocalizedError {
    let command: String
    let output: String
    
    public var errorDescription: String? {
        if output.isEmpty {
            return "Tests failed when running: \(command)"
        } else {
            return "Tests failed when running: \(command)\n\nTest output:\n\(output)"
        }
    }
}
