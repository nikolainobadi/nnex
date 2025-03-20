//
//  ReleaseStore.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

struct ReleaseStore {
    private let shell: Shell
    private let picker: Picker
    
    init(shell: Shell, picker: Picker) {
        self.shell = shell
        self.picker = picker
    }
}


// MARK: - Upload
extension ReleaseStore {
    func uploadRelease(info: ReleaseInfo) throws -> String {
        let versionNumber = try getVersionNumber(info)
        let releaseNotes = try getReleaseNotes()
        let command = """
        gh release create \(versionNumber) \(info.binaryPath) --title "\(versionNumber)" --notes "\(releaseNotes)"
        """
        
        try shell.runAndPrint(command)
        
        print("GitHub release \(versionNumber) created and binary uploaded.")
        
        return try shell.run("gh release view --json assets -q '.assets[].url'")
    }
}


// MARK: - Private Methods
private extension ReleaseStore {
    func getReleaseNotes() throws -> String {
        // TODO: - may be useful to allow user to provide path to release notes files as well
        return try picker.getRequiredInput(.releaseNotes)
    }
    
    func incrementVersion(_ part: ReleaseVersionInfo.VersionPart, path: String) throws -> String {
        let previousVersion = try shell.run("gh release view --json tagName -q '.tagName'")
        
        print("found previous version:", previousVersion)
        
        return try VersionHandler.incrementVersion(for: part, path: path, previousVersion: previousVersion)
    }
    
    func getVersionNumber(_ info: ReleaseInfo) throws -> String {
        guard let versionInfo = info.versionInfo else {
            return try getVersionInput(path: info.projectPath)
        }
        
        switch versionInfo {
        case .version(let number):
            guard VersionHandler.isValidVersionNumber(number) else {
                throw VersionError.invalidVersionNumber
            }
            
            return number
        case .increment(let part):
            return try incrementVersion(part, path: info.projectPath)
        }
    }
    
    func getVersionInput(path: String) throws -> String {
        let input = try picker.getRequiredInput(.versionNumber)
        
        if let versionPart = ReleaseVersionInfo.VersionPart(string: input) {
            return try incrementVersion(versionPart, path: path)
        }
        
        guard VersionHandler.isValidVersionNumber(input) else {
            throw VersionError.invalidVersionNumber
        }
        
        return input
    }
}
