//
//  BinaryInfo.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

public struct BinaryInfo {
    public let path: String
    public let sha256: String
    
    public init(path: String, sha256: String) {
        self.path = path
        self.sha256 = sha256
    }
}
