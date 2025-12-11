//
//  PublishUtilities.swift
//  NnexKit
//
//  Created by Nikolai Nobadi on 8/26/25.
//

public enum PublishUtilities {
    /// Builds the binary for the given project and formula.
    /// - Parameters:
    ///   - formula: The Homebrew formula associated with the project.
    ///   - buildType: The type of build to perform.
    ///   - skipTesting: Whether or not to skip tests, if the formula contains a `TestCommand`
    ///   - shell: The shell instance to use for building.
    /// - Returns: The binary output including path(s) and hash(es).
    /// - Throws: An error if the build process fails.
    public static func buildBinary(formula: SwiftDataHomebrewFormula, buildType: BuildType, skipTesting: Bool, shell: any NnexShell) throws -> BinaryOutput {
        let testCommand = skipTesting ? nil : formula.testCommand
        let config = BuildConfig(projectName: formula.name, projectPath: formula.localProjectPath, buildType: buildType, extraBuildArgs: formula.extraBuildArgs, skipClean: false, testCommand: testCommand)
        let builder = ProjectBuilder(shell: shell, config: config)
        
        return try builder.build()
    }

    /// Creates tar.gz archives from binary output.
    /// - Parameters:
    ///   - binaryOutput: The binary output from the build.
    ///   - shell: The shell instance to use for archiving.
    /// - Returns: An array of archived binaries.
    /// - Throws: An error if archive creation fails.
    public static func createArchives(from binaryOutput: BinaryOutput, shell: any NnexShell) throws -> [ArchivedBinary] {
        let archiver = BinaryArchiver(shell: shell)
        
        switch binaryOutput {
        case .single(let path):
            return try archiver.createArchives(from: [path])
        case .multiple(let binaries):
            let binaryPaths = ReleaseArchitecture.allCases.compactMap({ binaries[$0] })
            
            return try archiver.createArchives(from: binaryPaths)
        }
    }

    /// Creates formula content based on the archived binaries and asset URLs.
    /// - Parameters:
    ///   - formula: The Homebrew formula.
    ///   - version: The version number for the release.
    ///   - archivedBinaries: The archived binaries with their SHA256 values.
    ///   - assetURLs: The asset URLs from the GitHub release.
    /// - Returns: The formula content as a string.
    /// - Throws: An error if formula generation fails.
    public static func makeFormulaContent(formula: SwiftDataHomebrewFormula, version: String, archivedBinaries: [ArchivedBinary], assetURLs: [String]) throws -> String {
        let formulaName = formula.name
        
        if archivedBinaries.count == 1 {
            // Single binary case
            guard let assetURL = assetURLs.first else {
                throw NnexError.missingSha256 // Should create a better error for missing URL
            }
            return FormulaContentGenerator.makeFormulaFileContent(
                name: formulaName,
                details: formula.details,
                homepage: formula.homepage,
                license: formula.license,
                version: version,
                assetURL: assetURL,
                sha256: archivedBinaries[0].sha256
            )
        } else {
            // Multiple binaries case - match archive paths to determine architecture
            var armArchive: ArchivedBinary?
            var intelArchive: ArchivedBinary?
            
            for archive in archivedBinaries {
                if archive.originalPath.contains("arm64-apple-macosx") {
                    armArchive = archive
                } else if archive.originalPath.contains("x86_64-apple-macosx") {
                    intelArchive = archive
                }
            }
            
            // Extract URLs - assuming first is ARM, second is Intel when both present
            var armURL: String?
            var intelURL: String?
            
            if armArchive != nil && intelArchive != nil {
                armURL = assetURLs.count > 0 ? assetURLs[0] : nil
                intelURL = assetURLs.count > 1 ? assetURLs[1] : nil
            } else if armArchive != nil {
                armURL = assetURLs.first
            } else if intelArchive != nil {
                intelURL = assetURLs.first
            }
            
            return FormulaContentGenerator.makeFormulaFileContent(
                name: formulaName,
                details: formula.details,
                homepage: formula.homepage,
                license: formula.license,
                version: version,
                armURL: armURL,
                armSHA256: armArchive?.sha256,
                intelURL: intelURL,
                intelSHA256: intelArchive?.sha256
            )
        }
    }
}
