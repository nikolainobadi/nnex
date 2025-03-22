//
//  VersionHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

public enum VersionHandler {
    public static func isValidVersionNumber(_ version: String) -> Bool {
        return version.range(of: #"^v?\d+\.\d+\.\d+$"#, options: .regularExpression) != nil
    }
    
    public static func incrementVersion(for part: ReleaseVersionInfo.VersionPart, path: String, previousVersion: String) throws -> String {
        let cleanedVersion = previousVersion.hasPrefix("v") ? String(previousVersion.dropFirst()) : previousVersion
        var components = cleanedVersion.split(separator: ".").compactMap { Int($0) }

        switch part {
        case .major:
            components[0] += 1
            components[1] = 0
            components[2] = 0
        case .minor:
            components[1] += 1
            components[2] = 0
        case .patch:
            components[2] += 1
        }
        
        return components.map(String.init).joined(separator: ".")
    }
}
