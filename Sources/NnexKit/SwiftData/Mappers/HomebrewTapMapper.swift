//
//  HomebrewTapMapper.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/11/25.
//

enum HomebrewTapMapper {
    static func toDomain(_ tap: SwiftDataHomebrewTap) -> HomebrewTap {
        let formulas = tap.formulas.map({ swiftDataFormula in
            var formula = HomebrewFormulaMapper.toDomain(swiftDataFormula)
            formula.tapLocalPath = tap.localPath
            return formula
        })
        
        return .init(name: tap.name, localPath: tap.localPath, remotePath: tap.remotePath, formulas: formulas)
    }
    
    static func toSwiftData(_ tap: HomebrewTap) -> SwiftDataHomebrewTap {
        return .init(name: tap.name, localPath: tap.localPath, remotePath: tap.remotePath)
    }
}
