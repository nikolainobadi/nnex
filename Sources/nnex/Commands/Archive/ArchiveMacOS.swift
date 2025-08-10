//
//  ArchiveMacOS.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Files
import NnexKit
import ArgumentParser
import Foundation
import SwiftPicker

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
        
        @Option(name: .shortAndLong, help: "Archive output location. Defaults to ./build/archives/")
        var output: String?
        
        @Option(help: "App export location. If not provided, app will not be exported.")
        var exportPath: String?
        
        @Option(help: "Export method: developer-id, development, or app-store. Defaults to developer-id.")
        var exportMethod: ExportMethod?
        
        @Flag(help: "Show detailed xcodebuild output.")
        var verbose: Bool = false
        
        @Flag(help: "Open archive location in Finder after completion.")
        var openFinder: Bool = false
        
        func run() throws {
            let shell = Nnex.makeShell()
            let picker = Nnex.makePicker()
            
            // Detect project
            let projectPath = try getProjectPath()
            let projectDetector = ProjectDetector(shell: shell)
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
                scheme: selectedScheme
            )
            
            // Create archive builder and execute
            let archiveBuilder = MacOSArchiveBuilder(shell: shell)
            let archiveResult = try archiveBuilder.archive(config: config)
            
            // Export if requested
            if config.exportOutputPath != nil {
                let _ = try archiveBuilder.exportApp(from: archiveResult, config: config)
            }
            
            // Open in Finder if requested
            if openFinder {
                let pathToOpen = config.exportOutputPath ?? config.archiveOutputPath
                try shell.runAndPrint("open -R \"\(pathToOpen)\"")
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
    
    func getScheme(projectInfo: ProjectInfo, projectDetector: ProjectDetector, picker: Picker) throws -> String {
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
    
    func buildArchiveConfig(projectPath: String, scheme: String) throws -> ArchiveConfig {
        let config = configuration ?? .release
        let archiveOutput = output ?? "./build/archives"
        let exportOutput = exportPath
        let method = exportMethod ?? (exportOutput != nil ? .developerID : nil)
        
        // Create archive output directory if it doesn't exist
        try Folder.current.createSubfolderIfNeeded(withName: "build/archives")
        
        // Create export output directory if needed
        if let exportOutput = exportOutput {
            let exportFolder = try Folder(path: exportOutput.hasPrefix("/") ? exportOutput : Folder.current.path + "/" + exportOutput)
            _ = exportFolder
        }
        
        return ArchiveConfig(
            platform: .macOS,
            projectPath: projectPath,
            scheme: scheme,
            configuration: config,
            archiveOutputPath: archiveOutput.hasPrefix("/") ? archiveOutput : Folder.current.path + "/" + archiveOutput,
            exportOutputPath: exportOutput.map { path in
                path.hasPrefix("/") ? path : Folder.current.path + "/" + path
            },
            exportMethod: method,
            verbose: verbose,
            openInFinder: openFinder
        )
    }
}

// MARK: - ArgumentParser Conformance
extension BuildConfiguration: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument.capitalized)
    }
}

extension ExportMethod: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument)
    }
}
