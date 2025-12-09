//
//  FirstSchema.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

@preconcurrency import SwiftData

public enum FirstSchema: VersionedSchema {
    public static let versionIdentifier: Schema.Version = .init(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        return [
            HomebrewTap.self,
            HomebrewFormula.self
        ]
    }
}


// MARK: - Tap
extension FirstSchema {
    @Model
    public final class HomebrewTap {
        @Attribute(.unique) public var name: String
        @Attribute(.unique) public var localPath: String
        @Attribute(.unique) public var remotePath: String
        @Relationship(deleteRule: .cascade, inverse: \HomebrewFormula.tap) public var formulas: [HomebrewFormula] = []

        public init(name: String, localPath: String, remotePath: String) {
            self.name = name
            self.localPath = localPath
            self.remotePath = remotePath
        }
    }
}


// MARK: - Formula
extension FirstSchema {
    @Model
    public final class HomebrewFormula {
        public var name: String
        public var details: String
        public var homepage: String
        public var license: String
        public var localProjectPath: String
        public var uploadType: FormulaUploadType
        public var testCommand: TestCommand?
        public var extraBuildArgs: [String]
        public var tap: HomebrewTap?

        public init(
            name: String,
            details: String,
            homepage: String,
            license: String,
            localProjectPath: String,
            uploadType: FormulaUploadType,
            testCommand: TestCommand?,
            extraBuildArgs: [String]
        ) {
            self.name = name
            self.details = details
            self.homepage = homepage
            self.license = license
            self.localProjectPath = localProjectPath
            self.uploadType = uploadType
            self.testCommand = testCommand
            self.extraBuildArgs = extraBuildArgs
        }
    }
    
    public enum FormulaUploadType: String, Codable, Sendable {
        case binary
        case tarball
    }

    public enum TestCommand: Codable, Sendable {
        case defaultCommand
        case custom(String)
    }
}
