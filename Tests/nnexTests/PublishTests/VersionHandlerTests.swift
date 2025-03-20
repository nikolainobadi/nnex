//
//  VersionHandlerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Testing
@testable import nnex

struct VersionHandlerTests {
    @Test("Validates correct version numbers")
    func validVersionNumber() throws {
        #expect(VersionHandler.isValidVersionNumber("1.0.0"))
        #expect(VersionHandler.isValidVersionNumber("v2.3.4"))
    }
    
    @Test("Rejects incorrect version numbers")
    func invalidVersionNumber() throws {
        #expect(!VersionHandler.isValidVersionNumber("1.0"))
        #expect(!VersionHandler.isValidVersionNumber("1.0.0.0"))
        #expect(!VersionHandler.isValidVersionNumber("abc"))
        #expect(!VersionHandler.isValidVersionNumber("v1..0"))
    }
    
    @Test("Increments major version correctly")
    func incrementMajorVersion() throws {
        #expect(try VersionHandler.incrementVersion(for: .major, path: "", previousVersion: "1.0.0") == "2.0.0")
        #expect(try VersionHandler.incrementVersion(for: .major, path: "", previousVersion: "v2.1.3") == "3.0.0")
    }
    
    @Test("Increments minor version correctly")
    func incrementMinorVersion() throws {
        #expect(try VersionHandler.incrementVersion(for: .minor, path: "", previousVersion: "1.2.3") == "1.3.0")
        #expect(try VersionHandler.incrementVersion(for: .minor, path: "", previousVersion: "v0.9.9") == "0.10.0")
    }
    
    @Test("Increments patch version correctly")
    func incrementPatchVersion() throws {
        #expect(try VersionHandler.incrementVersion(for: .patch, path: "", previousVersion: "1.0.0") == "1.0.1")
        #expect(try VersionHandler.incrementVersion(for: .patch, path: "", previousVersion: "v1.9.9") == "1.9.10")
    }
}
