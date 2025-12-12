//
//  PublishInfoStoreAdapter.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/11/25.
//

import Foundation

public final class PublishInfoStoreAdapter {
    private let context: NnexContext
    
    public init(context: NnexContext) {
        self.context = context
    }
}


// MARK: - PublishInfoStore
extension PublishInfoStoreAdapter: PublishInfoStore {
    public func loadTaps() throws -> [HomebrewTap] {
        let swiftDataTaps = try context.loadTaps()
        
        return swiftDataTaps.map(HomebrewTapMapper.toDomain)
    }
    
    public func updateFormula(_ formula: HomebrewFormula) throws {
        let swiftDataFormulas = try context.loadFormulas()
        guard let target = swiftDataFormulas.first(where: { $0.name == formula.name }) else {
            return
        }
        
        target.details = formula.details
        target.homepage = formula.homepage
        target.license = formula.license
        target.localProjectPath = formula.localProjectPath
        target.uploadType = CurrentSchema.FormulaUploadType(rawValue: formula.uploadType.rawValue) ?? .binary
        target.testCommand = toSwiftDataTestCommand(formula.testCommand)
        target.extraBuildArgs = formula.extraBuildArgs
        
        try context.saveChanges()
    }
    
    public func saveNewFormula(_ formula: HomebrewFormula, in tap: HomebrewTap) throws {
        let swiftDataTaps = try context.loadTaps()
        guard let swiftDataTap = swiftDataTaps.first(where: { $0.name == tap.name }) else {
            throw NnexError.missingTap
        }
        
        let swiftDataFormula = HomebrewFormulaMapper.toSwiftData(formula)
        
        try context.saveNewFormula(swiftDataFormula, in: swiftDataTap)
    }
}


// MARK: - Helpers
private extension PublishInfoStoreAdapter {
    func toSwiftDataTestCommand(_ testCommand: HomebrewFormula.TestCommand?) -> CurrentSchema.TestCommand? {
        guard let testCommand else { return nil }
        
        switch testCommand {
        case .defaultCommand:
            return .defaultCommand
        case .custom(let command):
            return .custom(command)
        }
    }
}
