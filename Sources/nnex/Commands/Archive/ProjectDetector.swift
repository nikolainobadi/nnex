//
//  ProjectDetector.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Files
import Foundation
import NnexKit

protocol ProjectDetector {
    func detectProject(at path: String) throws -> ProjectInfo
    func detectSchemes(for project: ProjectInfo) throws -> [String]
    func validatePlatformSupport(_ platform: ArchivePlatform, project: ProjectInfo) throws
}

struct DefaultProjectDetector: ProjectDetector {
    private let shell: Shell
    
    init(shell: Shell) {
        self.shell = shell
    }
}


// MARK: - Actions
extension DefaultProjectDetector {
    /// Detects Xcode project or workspace in the specified directory
    func detectProject(at path: String) throws -> ProjectInfo {
        let folder = try Folder(path: path)
        
        // Look for workspace first, then project
        let workspaceFiles = folder.files.filter { $0.extension == "xcworkspace" }
        let projectFiles = folder.subfolders.filter { $0.extension == "xcodeproj" }
        
        let projectType: ProjectType
        
        if let workspace = workspaceFiles.first {
            projectType = .xcworkspace(workspace.path)
        } else if let project = projectFiles.first {
            projectType = .xcodeproj(project.path)
        } else {
            throw ArchiveError.noXcodeProject(path: path)
        }
        
        // Detect supported platforms (simplified for now)
        let supportedPlatforms = try detectSupportedPlatforms(projectType: projectType)
        
        return ProjectInfo(
            path: path,
            type: projectType,
            name: projectType.name,
            supportedPlatforms: supportedPlatforms
        )
    }
    
    /// Detects available schemes for the project
    func detectSchemes(for project: ProjectInfo) throws -> [String] {
        let projectPath = project.type.path
        let listCommand = "xcodebuild -list -project \"\(projectPath)\""
        
        let output = try shell.run(listCommand)
        
        // Parse schemes from xcodebuild -list output
        let schemes = parseSchemes(from: output)
        
        guard !schemes.isEmpty else {
            throw ArchiveError.noSchemesFound(projectName: project.name)
        }
        
        return schemes
    }
    
    /// Validates that the project supports the specified platform
    func validatePlatformSupport(_ platform: ArchivePlatform, project: ProjectInfo) throws {
        guard project.supportedPlatforms.contains(where: { $0.matches(platform) }) else {
            throw ArchiveError.platformNotSupported(
                platform: platform,
                projectName: project.name,
                supportedPlatforms: project.supportedPlatforms
            )
        }
    }
}


// MARK: - Private Methods
private extension DefaultProjectDetector {
    func detectSupportedPlatforms(projectType: ProjectType) throws -> [ArchivePlatform] {
        // For now, return both platforms - we could enhance this later
        // by actually parsing the project file to detect supported platforms
        return [.macOS, .iOS]
    }
    
    func parseSchemes(from output: String) -> [String] {
        let lines = output.components(separatedBy: .newlines)
        var schemes: [String] = []
        var inSchemesSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine == "Schemes:" {
                inSchemesSection = true
                continue
            }
            
            if inSchemesSection {
                // Stop when we hit another section or empty line after schemes
                if trimmedLine.isEmpty || (trimmedLine.contains(":") && !trimmedLine.hasPrefix(" ")) {
                    break
                }
                
                // Extract scheme name
                if !trimmedLine.isEmpty {
                    schemes.append(trimmedLine)
                }
            }
        }
        
        return schemes
    }
}


// MARK: - ArchivePlatform Extensions
private extension ArchivePlatform {
    func matches(_ other: ArchivePlatform) -> Bool {
        return self == other
    }
}


// MARK: - ArchiveError
enum ArchiveError: Error, LocalizedError {
    case noXcodeProject(path: String)
    case noSchemesFound(projectName: String)
    case platformNotSupported(platform: ArchivePlatform, projectName: String, supportedPlatforms: [ArchivePlatform])
    case archiveFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .noXcodeProject(let path):
            return "No Xcode project or workspace found in '\(path)'. Make sure you're in a directory containing an .xcodeproj or .xcworkspace file."
        case .noSchemesFound(let projectName):
            return "No schemes found for project '\(projectName)'. Make sure your project has at least one valid scheme."
        case .platformNotSupported(let platform, let projectName, let supported):
            return "Platform '\(platform)' is not supported by project '\(projectName)'. Supported platforms: \(supported)"
        case .archiveFailed(let reason):
            return "Archive failed: \(reason)"
        }
    }
}


// MARK: - ProjectInfo
struct ProjectInfo {
    let path: String
    let type: ProjectType
    let name: String
    let supportedPlatforms: [ArchivePlatform]
}


// MARK: - ProjectType
enum ProjectType {
    case xcodeproj(String)
    case xcworkspace(String)
    
    var path: String {
        switch self {
        case .xcodeproj(let path), .xcworkspace(let path):
            return path
        }
    }
    
    var name: String {
        switch self {
        case .xcodeproj(let path):
            return String(path.split(separator: "/").last?.split(separator: ".").first ?? "")
        case .xcworkspace(let path):
            return String(path.split(separator: "/").last?.split(separator: ".").first ?? "")
        }
    }
}
