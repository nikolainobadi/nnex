//
//  ExecutableNameResolver.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Files
import NnexKit
import Foundation

struct ExecutableNameResolver {
    func getExecutableNames(from projectFolder: Folder) throws -> [String] {
        guard projectFolder.containsFile(named: "Package.swift") else {
            throw NSError(domain: "BuildError", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "No Package.swift file found in '\(projectFolder.path)'. This does not appear to be a Swift package."
            ])
        }
        
        let content: String
        do {
            content = try projectFolder.file(named: "Package.swift").readAsString()
        } catch {
            throw NSError(domain: "BuildError", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Failed to read Package.swift file: \(error.localizedDescription)"
            ])
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "BuildError", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "Package.swift file is empty or contains only whitespace."
            ])
        }
        
        let names: [String]
        do {
            names = try ExecutableDetector.getExecutables(packageManifestContent: content)
        } catch {
            throw NSError(domain: "BuildError", code: 6, userInfo: [
                NSLocalizedDescriptionKey: "Failed to parse executable targets from Package.swift: \(error.localizedDescription)"
            ])
        }
        
        guard !names.isEmpty else {
            throw NSError(domain: "BuildError", code: 7, userInfo: [
                NSLocalizedDescriptionKey: "No executable targets found in Package.swift. Make sure your package defines at least one executable product."
            ])
        }
        
        return names
    }
}