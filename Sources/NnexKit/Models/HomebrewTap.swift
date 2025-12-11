//
//  HomebrewTap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/11/25.
//

public struct HomebrewTap {
    public var name: String
    public var localPath: String
    public var remotePath: String
    public var formulas: [HomebrewFormula]
    
    public init(name: String, localPath: String, remotePath: String, formulas: [HomebrewFormula]) {
        self.name = name
        self.localPath = localPath
        self.remotePath = remotePath
        self.formulas = formulas
    }
}
