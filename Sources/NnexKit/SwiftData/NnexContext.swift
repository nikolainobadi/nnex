//
//  NnexContext.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import SwiftData
import Foundation
import NnSwiftDataKit

/// Manages the SwiftData model context and application configuration.
public final class NnexContext {
    private let defaults: UserDefaults
    private let defaultBuildTypeKey = "defaultBuildTypeKey"
    private let tapListFolderPathKey = "tapListFolderPathKey"

    /// The model context for interacting with SwiftData models.
    public let context: ModelContext

    /// Initializes a new NnexContext instance.
    /// - Parameters:
    ///   - appGroupId: The application group identifier.
    ///   - config: An optional model configuration.
    ///   - defaults: An optional UserDefaults instance.
    public init(appGroupId: String, config: ModelConfiguration? = nil, defaults: UserDefaults? = nil) throws {
        if let config, let defaults {
            let container = try ModelContainer(for: SwiftDataTap.self, configurations: config)
            self.context = .init(container)
            self.defaults = defaults
        } else {
            let (config, defaults) = try configureSwiftDataContainer(appGroupId: appGroupId)
            let container = try ModelContainer(for: SwiftDataTap.self, configurations: config)
            self.context = .init(container)
            self.defaults = defaults
        }
    }
}

// MARK: - UserDefaults
extension NnexContext {
    /// Saves the folder path for the tap list.
    /// - Parameter path: The folder path to save.
    public func saveTapListFolderPath(path: String) {
        defaults.set(path, forKey: tapListFolderPathKey)
    }

    /// Loads the folder path for the tap list.
    /// - Returns: The saved folder path or nil if not set.
    public func loadTapListFolderPath() -> String? {
        guard let path = defaults.string(forKey: tapListFolderPathKey), !path.isEmpty else { return nil }
        return path
    }

    /// Saves the default build type.
    /// - Parameter buildType: The build type to save.
    public func saveDefaultBuildType(_ buildType: BuildType) {
        defaults.set(buildType, forKey: defaultBuildTypeKey)
    }

    /// Loads the default build type.
    /// - Returns: The saved build type or a default value if not set.
    public func loadDefaultBuildType() -> BuildType {
        return defaults.object(forKey: defaultBuildTypeKey) as? BuildType ?? .universal
    }
}

// MARK: - SwiftData
extension NnexContext {
    /// Loads all saved taps from the SwiftData context.
    /// - Returns: An array of SwiftDataTap objects.
    public func loadTaps() throws -> [SwiftDataTap] {
        return try context.fetch(FetchDescriptor<SwiftDataTap>())
    }

    /// Loads all saved formulas from the SwiftData context.
    /// - Returns: An array of SwiftDataFormula objects.
    public func loadFormulas() throws -> [SwiftDataFormula] {
        return try context.fetch(FetchDescriptor<SwiftDataFormula>())
    }

    /// Saves a new tap with associated formulas.
    /// - Parameters:
    ///   - tap: The tap to save.
    ///   - formulas: An optional array of formulas to associate with the tap.
    public func saveNewTap(_ tap: SwiftDataTap, formulas: [SwiftDataFormula] = []) throws {
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
    public func deleteTap(_ tap: SwiftDataTap) throws {
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
    public func saveNewFormula(_ formula: SwiftDataFormula, in tap: SwiftDataTap) throws {
        context.insert(formula)
        tap.formulas.append(formula)
        formula.tap = tap
        try context.save()
    }
    
    public func saveChanges() throws {
        try context.save()
    }
}
