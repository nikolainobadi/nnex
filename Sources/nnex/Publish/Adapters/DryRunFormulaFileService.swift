//
//  DryRunFormulaFileService.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/14/25.
//

import NnexKit

struct DryRunFormulaFileService: FormulaFileService {
    func resolveFormulaFile(formula: HomebrewFormula, tapFolder: any Directory, contents: String) throws -> FilePath {
        let fileName = "\(formula.name).rb"
        print(
            """
            \("Formula File Details".underline)
            fileName: \(fileName)
            filePath (if created): \(tapFolder.path.appendingPathComponent("Formula/\(fileName)"))
            
            \("Formula Contents".underline)
            \(contents)
            
            """
        )
        
        return "No formula file was created, and any previous formula file for \(formula.name) remains unmodified."
    }
}
