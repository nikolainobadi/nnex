//
//  NnexContext.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import SwiftData
import Foundation
import NnSwiftDataKit

public final class NnexContext {
    private let context: ModelContext
    private let defaults: UserDefaults
    private let defaultBuildTypeKey = "defaultBuildTypeKey"
    private let tapListFolderPathKey = "tapListFolderPathKey"

    init(schema: Schema, userDefaultsTestSuiteName: String?) throws {
        let identifier = "com.nobadi.nnex"
        let oldAppGroupId = "R8SJ24LQF3.\(identifier)"
//        let appGroupId = "group.\(identifier)" // TODO: -
        let appGroupId = oldAppGroupId
        
        if let userDefaultsTestSuiteName {
            defaults = .init(suiteName: userDefaultsTestSuiteName)!
            defaults.removePersistentDomain(forName: userDefaultsTestSuiteName)
            context = try .init(.init(for: schema, configurations: .init(isStoredInMemoryOnly: true)))
        } else {
            // TODO: -
//            try migrateAppGroupSwiftDataStoreIfNeeded(from: oldAppGroupId, to: appGroupId)
            let (container, defaults) = try makeAppGroupModelContainer(schema: schema, appGroupId: appGroupId)
            
            self.defaults = defaults
            self.context = .init(container)
        }
    }
}


// MARK: - Init
public extension NnexContext {
    convenience init( userDefaultsTestSuiteName: String? = nil) throws {
        try self.init(schema: .init(versionedSchema: CurrentSchema.self), userDefaultsTestSuiteName: userDefaultsTestSuiteName)
    }
}


// MARK: - UserDefaults
public extension NnexContext {
    /// Saves the folder path for the tap list.
    /// - Parameter path: The folder path to save.
    func saveTapListFolderPath(path: String) {
        defaults.set(path, forKey: tapListFolderPathKey)
    }

    /// Loads the folder path for the tap list.
    /// - Returns: The saved folder path or nil if not set.
    func loadTapListFolderPath() -> String? {
        guard let path = defaults.string(forKey: tapListFolderPathKey), !path.isEmpty else { return nil }
        return path
    }

    /// Saves the default build type.
    /// - Parameter buildType: The build type to save.
    func saveDefaultBuildType(_ buildType: BuildType) {
        defaults.set(buildType, forKey: defaultBuildTypeKey)
    }

    /// Loads the default build type.
    /// - Returns: The saved build type or a default value if not set.
    func loadDefaultBuildType() -> BuildType {
        return defaults.object(forKey: defaultBuildTypeKey) as? BuildType ?? .universal
    }
}


// MARK: - SwiftData
public extension NnexContext {
    /// Loads all saved taps from the SwiftData context.
    /// - Returns: An array of SwiftDataHomebrewTap objects.
    func loadTaps() throws -> [SwiftDataHomebrewTap] {
        return try context.fetch(FetchDescriptor<SwiftDataHomebrewTap>())
    }

    /// Loads all saved formulas from the SwiftData context.
    /// - Returns: An array of SwiftDataHomebrewFormula objects.
    func loadFormulas() throws -> [SwiftDataHomebrewFormula] {
        return try context.fetch(FetchDescriptor<SwiftDataHomebrewFormula>())
    }

    /// Saves a new tap with associated formulas.
    /// - Parameters:
    ///   - tap: The tap to save.
    ///   - formulas: An optional array of formulas to associate with the tap.
    func saveNewTap(_ tap: SwiftDataHomebrewTap, formulas: [SwiftDataHomebrewFormula] = []) throws {
        context.insert(tap)
        for formula in formulas {
            context.insert(formula)
            tap.formulas.append(formula)
            formula.tap = tap
        }
        try context.save()
    }

    /// Deletes the specified tap and its associated formulas.
    /// - Parameter tap: The tap to delete.
    func deleteTap(_ tap: SwiftDataHomebrewTap) throws {
        for formula in tap.formulas {
            context.delete(formula)
        }
        context.delete(tap)
        try context.save()
    }

    /// Saves a new formula and associates it with a given tap.
    /// - Parameters:
    ///   - formula: The formula to save.
    ///   - tap: The tap to associate with the formula.
    func saveNewFormula(_ formula: SwiftDataHomebrewFormula, in tap: SwiftDataHomebrewTap) throws {
        context.insert(formula)
        tap.formulas.append(formula)
        formula.tap = tap
        try context.save()
    }
    
    func deleteFormula(_ formula: SwiftDataHomebrewFormula) throws {
        context.delete(formula)
        try context.save()
    }
    
    func saveChanges() throws {
        try context.save()
    }
}
