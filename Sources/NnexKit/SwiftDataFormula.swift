//
//  SwiftDataFormula.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import SwiftData

@Model
public final class SwiftDataFormula {
    public var name: String
    public var details: String
    public var homepage: String
    public var license: String
    public var localProjectPath: String
    public var uploadType: FormulaUploadType
    public var tap: SwiftDataTap?
    
    public init(name: String, details: String, homepage: String, license: String, localProjectPath: String, uploadType: FormulaUploadType) {
        self.name = name
        self.details = details
        self.homepage = homepage
        self.license = license
        self.localProjectPath = localProjectPath
        self.uploadType = uploadType
    }
}


// MARK: - Dependencies
public enum FormulaUploadType: String, Codable {
    case binary, tarball
}
