//
//  VersionHandlerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Testing
@testable import NnexKit

struct VersionHandlerTests {
    @Test(
        "Validates correct version numbers",
        arguments: ["1.0.0", "v2.3.4", "0.0.0", "v9.9.9", "10.5.3", "v0.0.1", "7.8.9", "v1.10.0"]
    )
    func validVersionNumber(version: String) throws {
        #expect(VersionHandler.isValidVersionNumber(version), "Expected version '\(version)' to be valid")
    }

    @Test(
        "Rejects incorrect version numbers",
        arguments: [
            "1.0", "1.0.0.0", "abc", "v1..0", "1.2.a", "1.0.0-", "-1.0.0", "v1.0.0.0"
        ]
    )
    func invalidVersionNumber(version: String) throws {
        #expect(!VersionHandler.isValidVersionNumber(version), "Expected version '\(version)' to be invalid")
    }

    @Test("Increments major version correctly", arguments: Args.validVersions.majorValues)
    func incrementMajorVersion(previousVersion: String, expectedVersion: String) throws {
        let incrementedVersion = try VersionHandler.incrementVersion(for: .major, path: "", previousVersion: previousVersion)
        
        #expect(incrementedVersion == expectedVersion, "Expected \(expectedVersion) but got \(incrementedVersion) for input \(previousVersion)")
    }

    @Test("Increments minor version correctly", arguments: Args.validVersions.minorValues)
    func incrementMinorVersion(previousVersion: String, expectedVersion: String) throws {
        let incrementedVersion = try VersionHandler.incrementVersion(for: .minor, path: "", previousVersion: previousVersion)
        
        #expect(incrementedVersion == expectedVersion, "Expected \(expectedVersion) but got \(incrementedVersion) for input \(previousVersion)")
    }

    @Test("Increments patch version correctly", arguments: Args.validVersions.patchValues)
    func incrementPatchVersion(previousVersion: String, expectedVersion: String) throws {
        let incrementedVersion = try VersionHandler.incrementVersion(for: .patch, path: "", previousVersion: previousVersion)
        
        #expect(incrementedVersion == expectedVersion, "Expected \(expectedVersion) but got \(incrementedVersion) for input \(previousVersion)")
    }
}


// MARK: - Argument Helpers
private extension VersionHandlerTests {
    enum Args {
        case validVersions
        
        var majorValues: [(String, String)] {
            return [
                ("0.0.0", "1.0.0"), ("9.9.9", "10.0.0"), ("v0.0.0", "1.0.0"), ("v9.9.9", "10.0.0"),
                ("1.0.0", "2.0.0"), ("2.3.4", "3.0.0"), ("v3.2.1", "4.0.0"), ("5.6.7", "6.0.0"), ("v7.8.9", "8.0.0")
            ]
        }
        
        var minorValues: [(String, String)] {
            return majorValues.map { (version, _) in
                let components = version
                    .trimmingCharacters(in: ["v"])
                    .split(separator: ".")
                    .compactMap { Int($0) }
                
                let newVersion = "v\(components[0]).\(components[1] + 1).0"
                return (version, newVersion.trimmingCharacters(in: ["v"]))
            }
        }
        
        var patchValues: [(String, String)] {
            return majorValues.map { (version, _) in
                let components = version
                    .trimmingCharacters(in: ["v"])
                    .split(separator: ".")
                    .compactMap { Int($0) }
                
                let newVersion = "v\(components[0]).\(components[1]).\(components[2] + 1)"
                return (version, newVersion.trimmingCharacters(in: ["v"]))
            }
        }
    }
}
