//
//  HomebrewFormulaMapper.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/11/25.
//

enum HomebrewFormulaMapper {
    static func toDomain(_ formula: SwiftDataHomebrewFormula) -> HomebrewFormula {
        return .init(
            name: formula.name,
            details: formula.details,
            homepage: formula.homepage,
            license: formula.license,
            localProjectPath: formula.localProjectPath,
            uploadType: .init(rawValue: formula.uploadType.rawValue) ?? .tarball,
            testCommand: toDomainTestCommand(formula.testCommand),
            extraBuildArgs: formula.extraBuildArgs
        )
    }
    
    static func toSwiftData(_ formula: HomebrewFormula) -> SwiftDataHomebrewFormula {
        return .init(
            name: formula.name,
            details: formula.details,
            homepage: formula.homepage,
            license: formula.license,
            localProjectPath: formula.localProjectPath,
            uploadType: .init(rawValue: formula.uploadType.rawValue) ?? .tarball,
            testCommand: toSwiftDataTestCommand(formula.testCommand),
            extraBuildArgs: formula.extraBuildArgs
        )
    }
}


// MARK: - Helpers
private extension HomebrewFormulaMapper {
    static func toDomainTestCommand(_ testCommand: CurrentSchema.TestCommand?) -> HomebrewFormula.TestCommand? {
        guard let testCommand else { return nil }
        
        switch testCommand {
        case .defaultCommand:
            return .defaultCommand
        case .custom(let command):
            return .custom(command)
        }
    }
    
    static func toSwiftDataTestCommand(_ testCommand: HomebrewFormula.TestCommand?) -> CurrentSchema.TestCommand? {
        guard let testCommand else { return nil }
        
        switch testCommand {
        case .defaultCommand:
            return .defaultCommand
        case .custom(let command):
            return .custom(command)
        }
    }
}

