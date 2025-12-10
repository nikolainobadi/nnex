//
//  ExecutableNameResolver.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

/// Resolves executable names from a Package.swift manifest in a given directory.
enum ExecutableNameResolver {
    /// Extracts executable names from the Package.swift file in the specified directory.
    /// - Parameter directory: The directory containing the Package.swift file.
    /// - Returns: An array of executable names found in the package manifest.
    /// - Throws: `ExecutableNameResolverError` if the manifest is missing, unreadable, empty, or contains no executables.
    static func getExecutableNames(from directory: any Directory) throws -> [String] {
        guard directory.containsFile(named: "Package.swift") else {
            throw ExecutableNameResolverError.missingPackageSwift(path: directory.path)
        }

        let content: String
        do {
            content = try directory.readFile(named: "Package.swift")
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
