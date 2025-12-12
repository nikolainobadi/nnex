//
//  HomebrewTapImportResult.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//


public struct HomebrewTapImportResult {
    public let tap: HomebrewTap
    public let warnings: [String]
    
    public init(tap: HomebrewTap, warnings: [String]) {
        self.tap = tap
        self.warnings = warnings
    }
}