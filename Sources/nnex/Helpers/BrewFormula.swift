//
//  BrewFormula.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import NnexKit

/// Represents a Homebrew formula with metadata and version information.
struct BrewFormula: Codable {
    /// The name of the formula.
    let name: String
    
    /// The description of the formula.
    let desc: String
    
    /// The homepage URL of the formula.
    let homepage: String
    
    /// The license of the formula, if available.
    let license: String?
    
    /// The version information of the formula.
    let versions: Versions

    /// Represents version details for a Homebrew formula.
    struct Versions: Codable {
        /// The stable version of the formula, if available.
        let stable: String?
    }
}


// MARK: - Extension Dependencies
extension SwiftDataFormula {
    /// Initializes a SwiftDataFormula instance from a BrewFormula.
    /// - Parameter brewFormula: The BrewFormula to convert.
    convenience init(from brewFormula: BrewFormula) {
        var uploadType = FormulaUploadType.binary
        
        if let stableURL = brewFormula.versions.stable {
            uploadType = stableURL.contains(".tar.gz") ? .tarball : .binary
        }

        self.init(
            name: brewFormula.name,
            details: brewFormula.desc,
            homepage: brewFormula.homepage,
            license: brewFormula.license ?? "",
            localProjectPath: "",
            uploadType: uploadType,
            extraBuildArgs: []
        )
    }
}
