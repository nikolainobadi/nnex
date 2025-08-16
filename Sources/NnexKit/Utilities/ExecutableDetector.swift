//
//  ExecutableDetector.swift
//  NnexKit
//
//  Created by Nikolai Nobadi on 3/25/25.
//

import Foundation

public enum ExecutableDetector {
    public static func getExecutables(packageManifestContent: String) throws -> [String] {
        let pattern = #"\.executable\s*\(\s*name:\s*"([^"]+)""#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: packageManifestContent, options: [], range: NSRange(location: 0, length: packageManifestContent.utf16.count))
        let names: [String] = matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: packageManifestContent) else {
                return nil
            }
            return String(packageManifestContent[range])
        }
        
        if names.isEmpty {
            throw NnexError.missingExecutable
        }
        
        return names
    }
}
