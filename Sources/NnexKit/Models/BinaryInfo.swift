//
//  BinaryInfo.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Represents information about a binary file, including its path and SHA256 hash.
public struct BinaryInfo {
    /// The file path to the binary.
    public let path: String
    
    /// The SHA256 hash of the binary file.
    public let sha256: String

    /// Initializes a new instance of BinaryInfo.
    /// - Parameters:
    ///   - path: The file path to the binary.
    ///   - sha256: The SHA256 hash of the binary file.
    public init(path: String, sha256: String) {
        self.path = path
        self.sha256 = sha256
    }
}
