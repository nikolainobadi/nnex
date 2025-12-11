//
//  HomebrewFormula.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

public struct HomebrewFormula {
    public var name: String
    public var details: String
    public var homepage: String
    public var license: String?
    // TODO: - versions
    
    public init(name: String, details: String, homepage: String, license: String? = nil) {
        self.name = name
        self.details = details
        self.homepage = homepage
        self.license = license
    }
}
