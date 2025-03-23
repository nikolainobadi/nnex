//
//  PublishInfoLoader.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files
import NnexKit

struct PublishInfoLoader {
    private let shell: Shell
    private let picker: Picker
    private let projectFolder: Folder
    private let gitHandler: GitHandler
    private let context: NnexContext
    
    init(shell: Shell, picker: Picker, projectFolder: Folder, context: NnexContext, gitHandler: GitHandler) {
        self.shell = shell
        self.picker = picker
        self.projectFolder = projectFolder
        self.context = context
        self.gitHandler = gitHandler
    }
}


// MARK: - Load
extension PublishInfoLoader {
    func loadPublishInfo() throws -> (SwiftDataTap, SwiftDataFormula) {
        let allTaps = try context.loadTaps()
        let tap = try getTap(allTaps: allTaps) ?? picker.requiredSingleSelection(title: "\(projectFolder.name) does not yet have a formula. Select a tap for this formula.", items: allTaps)
        
        if let formula = tap.formulas.first(where: { $0.name.lowercased() == projectFolder.name.lowercased() }) {
            return (tap, formula)
        }
        
        try picker.requiredPermission(prompt: "Could not find existing formula for \(projectFolder.name) in \(tap.name). Would you like to create a new one?")
        
        let newFormula = try createNewFormula(for: projectFolder)
        
        try context.saveNewFormula(newFormula, in: tap)
        
        return (tap, newFormula)
    }
}


// MARK: - Private Methods
private extension PublishInfoLoader {
    func getTap(allTaps: [SwiftDataTap]) -> SwiftDataTap? {
        return allTaps.first { tap in
            return tap.formulas.contains(where: { $0.name.lowercased() == projectFolder.name.lowercased() })
        }
    }
    
    func createNewFormula(for folder: Folder) throws -> SwiftDataFormula {
        let details = try picker.getRequiredInput(prompt: "Enter the description for this formula.")
        let homepage = try gitHandler.getRemoteURL(path: folder.path)
        let license = LicenseDetector.detectLicense(in: folder)
        let extraArgs = getExtraArgs()
        
        return .init(
            name: folder.name,
            details: details,
            homepage: homepage,
            license: license,
            localProjectPath: folder.path,
            uploadType: .binary,
            extraBuildArgs: extraArgs
        )
    }
    
    func getExtraArgs() -> [String] {
        return []
    }
}
