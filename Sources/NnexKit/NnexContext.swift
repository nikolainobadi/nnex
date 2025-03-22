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
    
    public init(config: ModelConfiguration? = nil, defaults: UserDefaults? = nil) throws {
        if let config, let defaults {
            let container = try ModelContainer(for: SwiftDataTap.self, configurations: config)
            
            self.context = .init(container)
            self.defaults = defaults
        } else {
            let url = URL(filePath: "../Resources/config.json", directoryHint: .notDirectory, relativeTo: URL(filePath: #file).deletingLastPathComponent())
            
            guard let data = try? Data(contentsOf: url), let json = try? JSONSerialization.jsonObject(with: data) as? [String: String], let appGroupId = json["appGroupId"] else {
                fatalError("""
                AppGroupId not found. A valid AppGroupId is required to initialize the shared context.
                            
                To fix this, create a file at the following path:
                    Resources/config.json
                            
                The file should contain the following JSON structure:
                {
                    "appGroupId": "AppGroupExampleId"
                }
                            
                Replace the example ID with your actual App Group ID.
                """)
            }
            
            let (config, defaults) = try configureSwiftDataContainer(appGroupId: appGroupId)
            let container = try ModelContainer(for: SwiftDataTap.self, configurations: config)
            
            self.context = .init(container)
            self.defaults = defaults
        }
    }
}


// MARK: - UserDefaults
public extension NnexContext {
    func saveTapListFolderPath(path: String) {
        defaults.set(path, forKey: tapListFolderPathKey)
    }
    
    func loadTapListFolderPath() -> String? {
        guard let path = defaults.string(forKey: tapListFolderPathKey), !path.isEmpty else {
            return nil
        }
        
        return path
    }
    
    func saveDefaultBuildType(_ buildType: BuildType) {
        defaults.set(buildType, forKey: defaultBuildTypeKey)
    }
    
    func loadDefaultBuildType() -> BuildType {
        return defaults.object(forKey: defaultBuildTypeKey) as? BuildType ?? .universal
    }
}


// MARK: - SwiftData
public extension NnexContext {
    func loadTaps() throws -> [SwiftDataTap] {
        return try context.fetch(FetchDescriptor<SwiftDataTap>())
    }
    
    func loadFormulas() throws -> [SwiftDataFormula] {
        return try context.fetch(FetchDescriptor<SwiftDataFormula>())
    }
    
    func saveNewTap(_ tap: SwiftDataTap, formulas: [SwiftDataFormula] = []) throws {
        context.insert(tap)
        
        for formula in formulas {
            context.insert(formula)
            tap.formulas.append(formula)
            formula.tap = tap
        }
        
        try context.save()
    }
    
    func deleteTap(_ tap: SwiftDataTap) throws {
        for formula in tap.formulas {
            context.delete(formula)
        }
        
        context.delete(tap)
        try context.save()
    }
    
    func saveNewFormula(_ formula: SwiftDataFormula, in tap: SwiftDataTap) throws {
        context.insert(formula)
        tap.formulas.append(formula)
        formula.tap = tap
        try context.save()
    }
}
