//
//  HomebrewFormula.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/11/25.
//

public struct HomebrewFormula {
    public var name: String
    public var details: String
    public var homepage: String
    public var license: String
    public var localProjectPath: String
    public var uploadType: FormulaUploadType
    public var testCommand: TestCommand?
    public var extraBuildArgs: [String]
    
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


// MARK: - Dependencies
public extension HomebrewFormula {
    enum FormulaUploadType: String {
        case binary
        case tarball
    }

    enum TestCommand {
        case defaultCommand
        case custom(String)
    }
}
