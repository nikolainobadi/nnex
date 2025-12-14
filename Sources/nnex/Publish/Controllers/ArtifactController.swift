//
//  ArtifactController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit

struct ArtifactController {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let gitHandler: any GitHandler
    private let fileSystem: any FileSystem
    private let delegate: any ArtifactDelegate
    
    init(shell: any NnexShell, picker: any NnexPicker, gitHandler: any GitHandler, fileSystem: any FileSystem, delegate: any ArtifactDelegate) {
        self.shell = shell
        self.picker = picker
        self.delegate = delegate
        self.gitHandler = gitHandler
        self.fileSystem = fileSystem
    }
}


// MARK: - BuildArtifacts
extension ArtifactController {
    func buildArtifacts(projectFolder folder: any Directory, buildType: BuildType, versionNumber: String) throws -> ReleaseArtifact {
        let formula = loadExistingFormula(named: folder.name)
        let buildResult = try buildExecutable(folder: folder, buildType: buildType, formula: formula)
        let archives = try makeArchives(result: buildResult)
        
        return .init(version: versionNumber, executableName: buildResult.executableName, archives: archives)
    }
}


// MARK: - Private Methods
private extension ArtifactController {
    func loadExistingFormula(named name: String) -> HomebrewFormula? {
        return try? delegate.loadTaps().flatMap({ $0.formulas }).first(where: { $0.name.matches(name) })
    }
    
    func buildExecutable(folder: any Directory, buildType: BuildType, formula: HomebrewFormula?) throws -> BuildResult {
        return try delegate.buildExecutable(
            projectFolder: folder,
            buildType: buildType,
            extraBuildArgs: formula?.extraBuildArgs ?? [],
            testCommand: formula?.testCommand
        )
    }
    
    func makeArchives(result: BuildResult) throws -> [ArchivedBinary] {
        let archiver = BinaryArchiver(shell: shell)
        
        switch result.binaryOutput {
        case .single(let path):
            return try archiver.createArchives(from: [path])
        case .multiple(let binaries):
            let binaryPaths = ReleaseArchitecture.allCases.compactMap({ binaries[$0] })
            
            return try archiver.createArchives(from: binaryPaths)
        }
    }
}


// MARK: - Dependencies
protocol ArtifactDelegate {
    func loadTaps() throws -> [HomebrewTap]
    func buildExecutable(projectFolder: any Directory, buildType: BuildType, extraBuildArgs: [String], testCommand: HomebrewFormula.TestCommand?) throws -> BuildResult
}
