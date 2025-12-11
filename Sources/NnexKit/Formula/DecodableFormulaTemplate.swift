//
//  DecodableFormulaTemplate.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Represents a Homebrew formula with metadata and version information.
public struct DecodableFormulaTemplate: Codable {
    /// The name of the formula.
    public let name: String
    
    /// The description of the formula.
    public let desc: String
    
    /// The homepage URL of the formula.
    public let homepage: String
    
    /// The license of the formula, if available.
    public let license: String?
    
    /// The version information of the formula.
    public let versions: Versions

    /// Represents version details for a Homebrew formula.
    public struct Versions: Codable {
        /// The stable version of the formula, if available.
        public let stable: String?
        
        public init(stable: String?) {
            self.stable = stable
        }
    }
    
    public init(name: String, desc: String, homepage: String, license: String?, versions: Versions) {
        self.name = name
        self.desc = desc
        self.homepage = homepage
        self.license = license
        self.versions = versions
    }
}
