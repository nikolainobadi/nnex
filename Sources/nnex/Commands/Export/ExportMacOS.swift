//
//  ExportMacOS.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Files
import NnexKit
import Foundation
import ArgumentParser
import SwiftPickerKit

extension Nnex.Export {
    struct MacOS: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Export a macOS application archive."
        )
        
        @Option(name: .shortAndLong, help: "Path to the .xcarchive to export. If not provided, will archive the current project first.")
        var archive: String?
        
        @Option(name: .shortAndLong, help: "Path to the project directory. Defaults to the current directory.")
        var path: String?
        
        @Option(help: "Xcode scheme to archive. Auto-detected if not provided.")
        var scheme: String?
        
        @Option(help: "Build configuration: Debug or Release. Defaults to Release.")
        var configuration: BuildConfiguration?
        
        @Option(name: .shortAndLong, help: "Export output location. Defaults to ~/Desktop/appName_readableDate")
        var output: String?
        
        @Flag(help: "Show detailed output during archiving, notarization and export.")
        var verbose: Bool = false
        
        @Flag(help: "Open export location in Finder after completion.")
        var openFinder: Bool = false
        
        @Flag(help: "Build for single architecture only (current machine). Defaults to universal binary.")
        var singleArchitecture: Bool = false
        
        @Flag(help: "Skip binary stripping to preserve debug symbols. Defaults to stripped binary.")
        var noStrip: Bool = false
        
        func run() throws {
            // TODO: - 
            let shell = Nnex.makeShell()
            let picker = Nnex.makePicker()
            let projectDetector = Nnex.makeProjectDetector()
            let archiveBuilder = Nnex.makeMacOSArchiveBuilder()
            let notarizeHandler = Nnex.makeNotarizeHandler()
            let exportHandler = Nnex.makeExportHandler()
            
            // Get archive path - either provided or create new one
            let archivePath = try getOrCreateArchive(
                shell: shell,
                picker: picker,
                projectDetector: projectDetector,
                archiveBuilder: archiveBuilder
            )
            print("📦 Using archive: \(archivePath)")
            
            // Check if archive is already notarized
            let isNotarized = try notarizeHandler.isArchiveNotarized(archivePath)
            
            if isNotarized {
                print("✅ Archive is already notarized")
            } else {
                print("🔒 Archive needs notarization...")
                try notarizeHandler.notarizeAndStaple(archivePath: archivePath, verbose: verbose)
                print("✅ Notarization and stapling completed")
            }
            
            // Export the app
            let exportPath = try getExportPath(archivePath: archivePath)
            try exportHandler.exportApp(archivePath: archivePath, outputPath: exportPath, verbose: verbose)
            
            print("✅ Export completed successfully!")
            print("   Location: \(exportPath)")
            
            // Open in Finder if requested
            if openFinder {
                _ = try shell.bash("open -R \"\(exportPath)\"")
            }
        }
    }
}


// MARK: - Private Methods
private extension Nnex.Export.MacOS {
    func getOrCreateArchive(
        shell: any NnexShell,
        picker: any NnexPicker,
        projectDetector: any ProjectDetector,
        archiveBuilder: any ArchiveBuilder
    ) throws -> String {
        if let archive = archive {
            return archive
        }
        
        // No archive provided - create new archive from current project
        print("📦 No archive specified, archiving current project...")
        
        let projectPath = try getProjectPath()
        let projectInfo = try projectDetector.detectProject(at: projectPath)
        
        print("🔍 Detected project: \(projectInfo.name)\(projectInfo.type.path.hasSuffix(".xcworkspace") ? ".xcworkspace" : ".xcodeproj")")
        
        // Validate macOS support
        try projectDetector.validatePlatformSupport(.macOS, project: projectInfo)
        
        // Get scheme
        let selectedScheme = try getScheme(projectInfo: projectInfo, projectDetector: projectDetector, picker: picker)
        print("📋 Using scheme: \(selectedScheme)")
        
        // Build archive config
        let config = try buildArchiveConfig(
            projectPath: projectPath,
            scheme: selectedScheme,
            shell: shell
        )
        
        // Create archive
        let result = try archiveBuilder.archive(config: config)
        return result.archivePath
    }
    
    func getProjectPath() throws -> String {
        if let path = path {
            let folder = try Folder(path: path)
            return folder.path
        }
        return Folder.current.path
    }
    
    func getScheme(projectInfo: ProjectInfo, projectDetector: any ProjectDetector, picker: any NnexPicker) throws -> String {
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
    
    func buildArchiveConfig(projectPath: String, scheme: String, shell: any NnexShell) throws -> ArchiveConfig {
        let config = configuration ?? .release
        let defaultArchiveLocation = NSString(string: "~/Library/Developer/Xcode/Archives").expandingTildeInPath
        let archiveOutput = defaultArchiveLocation
        
        // Create archive output directory if it doesn't exist
        _ = try shell.bash("mkdir -p \"\(archiveOutput)\"")
        
        return ArchiveConfig(
            platform: .macOS,
            projectPath: projectPath,
            scheme: scheme,
            configuration: config,
            archiveOutputPath: archiveOutput,
            verbose: verbose,
            openInFinder: false, // Don't open archive location, we're exporting
            universalBinary: !singleArchitecture,
            stripBinary: !noStrip
        )
    }
    
    func getExportPath(archivePath: String) throws -> String {
        if let output = output {
            return output
        }
        
        // Extract app name from archive path
        let archiveName = URL(fileURLWithPath: archivePath).deletingPathExtension().lastPathComponent
        let appName = archiveName.components(separatedBy: "_").first ?? "App"
        
        // Create readable date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let readableDate = formatter.string(from: Date())
        
        // Default to Desktop
        let desktopPath = NSString(string: "~/Desktop").expandingTildeInPath
        return "\(desktopPath)/\(appName)_\(readableDate).app"
    }
}
