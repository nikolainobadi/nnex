//
//  BinaryInfo.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Represents information about a binary file.
public struct BinaryInfo {
    /// The file path to the binary.
    public let path: String

    /// Initializes a new instance of BinaryInfo.
    /// - Parameters:
    ///   - path: The file path to the binary.
    public init(path: String) {
        self.path = path
    }
}
