//
//  ArchiveMacOS.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Files
import NnexKit
import Foundation
import NnShellKit
import SwiftPickerKit
import ArgumentParser

extension Nnex.Archive {
    struct MacOS: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Archive a macOS application."
        )
        
        @Option(name: .shortAndLong, help: "Path to the project directory. Defaults to the current directory.")
        var path: String?
        
        @Option(help: "Xcode scheme to archive. Auto-detected if not provided.")
        var scheme: String?
        
        @Option(help: "Build configuration: Debug or Release. Defaults to Release.")
        var configuration: BuildConfiguration?
        
        @Option(name: .shortAndLong, help: "Archive output location. Defaults to ~/Library/Developer/Xcode/Archives/")
        var output: String?
        
        
        @Flag(help: "Show detailed xcodebuild output.")
        var verbose: Bool = false
        
        @Flag(help: "Open archive location in Finder after completion.")
        var openFinder: Bool = false
        
        @Flag(help: "Build for single architecture only (current machine). Defaults to universal binary.")
        var singleArchitecture: Bool = false
        
        @Flag(help: "Skip binary stripping to preserve debug symbols. Defaults to stripped binary.")
        var noStrip: Bool = false
        
        func run() throws {
            let shell = Nnex.makeShell()
            let picker = Nnex.makePicker()
            let projectDetector = Nnex.makeProjectDetector()
            let archiveBuilder = Nnex.makeMacOSArchiveBuilder()
            let projectPath = try getProjectPath()
            let projectInfo = try projectDetector.detectProject(at: projectPath)
            
            print("🔍 Detected project: \(projectInfo.name)\(projectInfo.type.path.hasSuffix(".xcworkspace") ? ".xcworkspace" : ".xcodeproj")")
            
            // Validate macOS support
            try projectDetector.validatePlatformSupport(.macOS, project: projectInfo)
            
            // Get scheme
            let selectedScheme = try getScheme(projectInfo: projectInfo, projectDetector: projectDetector, picker: picker)
            print("📋 Using scheme: \(selectedScheme)")
            
            // Build configuration
            let config = try buildArchiveConfig(
                projectPath: projectPath,
                scheme: selectedScheme,
                shell: shell
            )
            
            // Execute archive
            let _ = try archiveBuilder.archive(config: config)
            
            // Open in Finder if requested
            if openFinder {
                _ = try shell.bash("open -R \"\(config.archiveOutputPath)\"")
            }
        }
    }
}


// MARK: - Private Methods
private extension Nnex.Archive.MacOS {
    func getProjectPath() throws -> String {
        if let path = path {
            let folder = try Folder(path: path)
            return folder.path
        }
        return Folder.current.path
    }
    
    func getScheme(projectInfo: ProjectInfo, projectDetector: ProjectDetector, picker: NnexPicker) throws -> String {
        if let scheme = scheme {
            return scheme
        }
        
        let availableSchemes = try projectDetector.detectSchemes(for: projectInfo)
        
        // If only one scheme, use it automatically
        guard availableSchemes.count > 1 else {
            return availableSchemes.first ?? projectInfo.name
        }
        
        // Multiple schemes - let user choose
        return try picker.requiredSingleSelection(
            title: "Multiple schemes detected. Which would you like to archive?",
            items: availableSchemes
        )
    }
    
    func buildArchiveConfig(projectPath: String, scheme: String, shell: any Shell) throws -> ArchiveConfig {
        let config = configuration ?? .release
        let defaultArchiveLocation = NSString(string: "~/Library/Developer/Xcode/Archives").expandingTildeInPath
        let archiveOutput = output ?? defaultArchiveLocation
        
        // Create archive output directory if it doesn't exist
        _ = try shell.bash("mkdir -p \"\(archiveOutput)\"")
        
        return .init(
            platform: .macOS,
            projectPath: projectPath,
            scheme: scheme,
            configuration: config,
            archiveOutputPath: archiveOutput.hasPrefix("/") ? archiveOutput : Folder.current.path + "/" + archiveOutput,
            verbose: verbose,
            openInFinder: openFinder,
            universalBinary: !singleArchitecture,
            stripBinary: !noStrip
        )
    }
}

// MARK: - ArgumentParser Conformance
extension BuildConfiguration: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument.capitalized)
    }
}

