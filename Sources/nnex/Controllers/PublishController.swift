//
//  PublishController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Foundation
import NnexKit

struct PublishController {
    private let picker: any NnexPicker
    private let folderBrowser: any DirectoryBrowser
    private let fileSystem: any FileSystem
    private let dateProvider: any DateProvider
    private let service: any PublishService
    private let releaseInfoService: any ReleaseInfoService
}


// MARK: - Actions
extension PublishController {
    func publish(projectPath: String?, versionSpecifier: ReleaseVersionSpecifier?, notes: ReleaseNotes?, commitMessage: String?) throws {
        // TODO: -
//        let projectFolder = try selectProjectFolder(at: projectPath)
//        let (releaseSpecifier, releaseNotes) = try releaseInfoService.makeReleaseInfo(projectFolder: projectFolder, versionSpecifier: versionSpecifier, notes: notes)
//        let tap = try selectTap(projectName: projectFolder.name)
//        let formula = try resolveFormula(projectName: projectFolder.name, in: tap)
//        let buildConfig = try service.makeBuildConfig(projectName: projectFolder.name, projectPath: projectFolder.path, testCommand: nil)
//        let request = makePublishRequest(projectFolder: projectFolder, tap: tap, formula: formula, releaseSpecifier: releaseSpecifier, notes: releaseNotes, commitMessage: commitMessage, buildConfig: buildConfig, previousVersion: previousVersion)
//
//        try service.publish(request: request)
    }
}


// MARK: - Project Selection
private extension PublishController {
    func selectProjectFolder(at path: String?) throws -> any Directory {
        guard let path else {
            return fileSystem.currentDirectory
        }

        return try fileSystem.directory(at: path)
    }
}


// MARK: - Tap and Formula
private extension PublishController {
    func selectTap(projectName: String) throws -> HomebrewTap {
        let taps = try service.availableTaps()

        if let tap = taps.first(where: { tap in
            return tap.formulas.contains(where: { $0.name.lowercased() == projectName.lowercased() })
        }) {
            return tap
        }

        return try picker.requiredSingleSelection("Select the Homebrew tap for \(projectName)", items: taps)
    }

    func resolveFormula(projectName: String, in tap: HomebrewTap) throws -> HomebrewFormula {
        if let formula = try service.resolveFormula(named: projectName, in: tap) {
            return formula
        }

        try picker.requiredPermission(prompt: "Could not find existing formula for \(projectName.yellow) in \(tap.name). Would you like to create a new one?")

        return try service.createFormula(named: projectName, in: tap)
    }
}


// MARK: - Publish Request
private extension PublishController {
    func makePublishRequest(projectFolder: any Directory, tap: HomebrewTap, formula: HomebrewFormula, releaseSpecifier: ReleaseVersionSpecifier, notes: ReleaseNotes, commitMessage: String?, buildConfig: BuildConfig, previousVersion: String?) -> PublishRequest {
        let commitMessage = commitMessage ?? "" // TODO: -
        let releasePlan = ReleasePlan(previousVersion: previousVersion, next: releaseSpecifier)
        
        return .init(projectName: projectFolder.name, projectPath: projectFolder.path, tap: tap, formula: formula, releasePlan: releasePlan, notes: notes, buildConfig: buildConfig, commitMessage: commitMessage)
    }
}


// MARK: - Dependencies
protocol PublishService {
    func availableTaps() throws -> [HomebrewTap]
    func publish(request: PublishRequest) throws
    func createFormula(named name: String, in tap: HomebrewTap) throws -> HomebrewFormula
    func resolveFormula(named name: String, in tap: HomebrewTap) throws -> HomebrewFormula?
    func makeBuildConfig(projectName: String, projectPath: String, testCommand: TestCommand?) throws -> BuildConfig
}

protocol ReleaseInfoService {
    func makeReleaseInfo(projectFolder: any Directory, versionSpecifier: ReleaseVersionSpecifier?, notes: ReleaseNotes?) throws -> (ReleaseVersionSpecifier, ReleaseNotes)
}

extension PublishController {
    enum NoteContentType: CaseIterable {
        case direct
        case selectFile
        case fromPath
        case createFile
    }
}


// MARK: - Extension Dependencies
private extension Date {
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: self)
    }
}




