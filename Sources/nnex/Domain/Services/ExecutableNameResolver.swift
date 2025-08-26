//
//  ExecutableNameResolver.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Files
import NnexKit

struct ExecutableNameResolver {
    func getExecutableNames(from projectFolder: Folder) throws -> [String] {
        guard projectFolder.containsFile(named: "Package.swift") else {
            throw ExecutableNameResolverError.missingPackageSwift(path: projectFolder.path)
        }
        
        let content: String
        do {
            content = try projectFolder.file(named: "Package.swift").readAsString()
        } catch {
            throw ExecutableNameResolverError.failedToReadPackageSwift(reason: error.localizedDescription)
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExecutableNameResolverError.emptyPackageSwift
        }
        
        let names: [String]
        do {
            names = try ExecutableDetector.getExecutables(packageManifestContent: content)
        } catch {
            throw ExecutableNameResolverError.failedToParseExecutables(reason: error.localizedDescription)
        }
        
        guard !names.isEmpty else {
            throw ExecutableNameResolverError.noExecutablesFound
        }
        
        return names
    }
}