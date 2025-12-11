//
//  SwiftDataHomebrewFormula+Extensions.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/25/25.
//

public extension SwiftDataHomebrewFormula {
    /// Initializes a SwiftDataHomebrewFormula instance from a BrewFormula.
    /// - Parameter brewFormula: The BrewFormula to convert.
    convenience init(from brewFormula: BrewFormula) {
        var uploadType = CurrentSchema.FormulaUploadType.binary
        
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
            testCommand: nil,
            extraBuildArgs: []
        )
    }
}
