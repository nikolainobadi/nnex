//
//  ArchivedBinary.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

public struct ArchivedBinary {
    public let originalPath: String
    public let archivePath: String
    public let sha256: String
    
    public init(originalPath: String, archivePath: String, sha256: String) {
        self.originalPath = originalPath
        self.archivePath = archivePath
        self.sha256 = sha256
    }
}
