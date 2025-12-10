//
//  PublishResult.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

public struct PublishResult: Sendable {
    public let version: String
    public let assetURLs: [String]
    public let formulaPath: String?

    public init(version: String, assetURLs: [String], formulaPath: String?) {
        self.version = version
        self.assetURLs = assetURLs
        self.formulaPath = formulaPath
    }
}
