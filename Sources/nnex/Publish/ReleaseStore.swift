//
//  ReleaseStore.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

struct ReleaseStore {
    private let shell: Shell
    private let picker: Picker
}


// MARK: - Upload
extension ReleaseStore {
    func uploadRelease(info: ReleaseInfo) throws -> String {
        let versionNumber = try getVersionNumber(info) // TODO: -
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
    
    func getVersionNumber(_ info: ReleaseInfo) throws -> String {
        guard let versionInfo = info.versionInfo else {
            return try getVersionInput(path: info.projectPath)
        }
        
        switch versionInfo {
        case .version(let number):
            guard isValidVersionNumber(number) else {
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
        
        guard isValidVersionNumber(input) else {
            throw VersionError.invalidVersionNumber
        }
        
        return input
    }
    
    func incrementVersion(_ part: ReleaseVersionInfo.VersionPart, path: String) throws -> String {
        let previousVersion = try shell.run("gh release view --json tagName -q '.tagName'")
        
        print("found previous version:", previousVersion)
        
        return try incrementVersion(for: part, path: path, previousVersion: previousVersion)
    }
    
    func isValidVersionNumber(_ version: String) -> Bool {
        return version.range(of: #"^v?\d+\.\d+\.\d+$"#, options: .regularExpression) != nil
    }
    
    func incrementVersion(for part: ReleaseVersionInfo.VersionPart, path: String, previousVersion: String) throws -> String {
        let cleanedVersion = previousVersion.hasPrefix("v") ? String(previousVersion.dropFirst()) : previousVersion
        var components = cleanedVersion.split(separator: ".").compactMap { Int($0) }

        switch part {
        case .major:
            components[0] += 1
            components[1] = 0
            components[2] = 0
        case .minor:
            components[1] += 1
            components[2] = 0
        case .patch:
            components[2] += 1
        }
        
        return components.map(String.init).joined(separator: ".")
    }
}


// MARK: - Dependencies
struct ReleaseInfo {
    let binaryPath: String
    let projectPath: String
    let versionInfo: ReleaseVersionInfo?
}
