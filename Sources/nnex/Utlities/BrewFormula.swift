//
//  BrewFormula.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import NnexKit

struct BrewFormula: Codable {
    let name: String
    let desc: String
    let homepage: String
    let license: String?
    let versions: Versions

    struct Versions: Codable {
        let stable: String?
    }
}


// MARK: - Extension Dependencies
extension SwiftDataFormula {
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
