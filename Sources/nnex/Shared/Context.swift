//
//  File.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import SwiftData
import Foundation
import NnSwiftDataKit

final class SharedContext {
    private let context: ModelContext
    private let defaults: UserDefaults
    
    init(config: ModelConfiguration? = nil, defaults: UserDefaults? = nil) throws {
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
extension SharedContext {
    func saveTapPath(path: String) {
        
    }
}


// MARK: - SwiftData
extension SharedContext {
    func loadTaps() throws -> [SwiftDataTap] {
        return try context.fetch(FetchDescriptor<SwiftDataTap>())
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


@Model
final class SwiftDataTap {
    @Attribute(.unique) var name: String
    @Attribute(.unique) var localPath: String
    @Attribute(.unique) var remotePath: String
    @Relationship(deleteRule: .cascade, inverse: \SwiftDataFormula.tap) public var formulas: [SwiftDataFormula] = []
    
    init(name: String, localPath: String, remotePath: String) {
        self.name = name
        self.localPath = localPath
        self.remotePath = remotePath
    }
}

@Model
final class SwiftDataFormula {
    var name: String
    var details: String
    var homepage: String
    var license: String
    var localProjectPath: String
    var uploadType: FormulaUploadType
    var tap: SwiftDataTap?
    
    init(name: String, details: String, homepage: String, license: String, localProjectPath: String, uploadType: FormulaUploadType) {
        self.name = name
        self.details = details
        self.homepage = homepage
        self.license = license
        self.localProjectPath = localProjectPath
        self.uploadType = uploadType
    }
}

enum FormulaUploadType: String, Codable {
    case binary, tarball
}
