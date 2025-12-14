//
//  ArtifactDelegateAdapter.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit

struct ArtifactDelegateAdapter {
    private let loader: PublishInfoStoreAdapter
    private let buildController: BuildController
    
    init(loader: PublishInfoStoreAdapter, buildController: BuildController) {
        self.loader = loader
        self.buildController = buildController
    }
}


// MARK: - ArtifactDelegate
extension ArtifactDelegateAdapter: ArtifactDelegate {
    func loadTaps() throws -> [HomebrewTap] {
        return try loader.loadTaps()
    }

    func buildExecutable(projectFolder: any Directory, buildType: BuildType, extraBuildArgs: [String], testCommand: HomebrewFormula.TestCommand?) throws -> BuildResult {
        return try buildController.buildExecutable(projectFolder: projectFolder, buildType: buildType, clean: true, outputLocation: .currentDirectory(buildType), extraBuildArgs: extraBuildArgs, testCommand: testCommand)
    }
}
