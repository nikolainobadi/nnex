//
//  PublishInfoLoader.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files

struct PublishInfoLoader {
    private let shell: Shell
    private let picker: Picker
    private let projectFolder: Folder
    private let context: SharedContext
    
    init(shell: Shell, picker: Picker, projectFolder: Folder, context: SharedContext) {
        self.shell = shell
        self.picker = picker
        self.projectFolder = projectFolder
        self.context = context
    }
}


// MARK: - Load
extension PublishInfoLoader {
    func loadPublishInfo() throws -> (SwiftDataTap, SwiftDataFormula) {
        guard let tap = try getTap() else {
            throw NnexError.missingTap
        }
        
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
    func getTap() throws -> SwiftDataTap? {
        return try context.loadTaps().first { tap in
            return tap.formulas.contains(where: { $0.name.lowercased() == projectFolder.name.lowercased() })
        }
    }
    
    func createNewFormula(for folder: Folder) throws -> SwiftDataFormula {
        let gitHandler = GitHandler(shell: shell)
        let details = try picker.getRequiredInput(.formulaDetails)
        let homepage = try gitHandler.getRemoteURL(path: folder.path)
        let license = detectLicense(in: folder)
        
        return .init(
            name: folder.name,
            details: details,
            homepage: homepage,
            license: license,
            localProjectPath: folder.path,
            uploadType: .binary
        )
    }
    
    func detectLicense(in folder: Folder) -> String {
        let licenseFiles = ["LICENSE", "LICENSE.md", "COPYING"]
        
        for fileName in licenseFiles {
            if let file = try? folder.file(named: fileName) {
                let content = try? file.readAsString()
                if let content = content {
                    if content.contains("MIT License") {
                        return "MIT"
                    } else if content.contains("Apache License") {
                        return "Apache"
                    } else if content.contains("GNU General Public License") {
                        return "GPL"
                    } else if content.contains("BSD License") {
                        return "BSD"
                    }
                }
            }
        }
        
        return ""
    }
}
