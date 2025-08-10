//
//  MacOSArchiveBuilder.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Files
import NnexKit
import Foundation

struct MacOSArchiveBuilder {
    private let shell: Shell
    
    init(shell: Shell) {
        self.shell = shell
    }
}


// MARK: - MacOSArchiveBuilder
extension MacOSArchiveBuilder: ArchiveBuilder {
    func archive(config: ArchiveConfig) throws -> ArchiveResult {
        print("🏗️  Archiving for macOS (\(config.configuration.rawValue) configuration)")
        
        // Ensure output directory exists
        try createDirectoryIfNeeded(config.archiveOutputPath)
        
        // Generate archive path with timestamp
        let timestamp = DateFormatter.archiveTimestamp.string(from: Date())
        let projectDetector = ProjectDetector(shell: shell)
        let projectInfo = try projectDetector.detectProject(at: config.projectPath)
        let archivePath = "\(config.archiveOutputPath)/\(projectInfo.name)_\(timestamp).xcarchive"
        
        // Build archive command
        let archiveCommand = buildArchiveCommand(
            projectType: projectInfo.type,
            scheme: config.scheme,
            configuration: config.configuration,
            archivePath: archivePath
        )
        
        if config.verbose {
            print("Executing: \(archiveCommand)")
        }
        
        // Execute archive command
        do {
            let output = try shell.run(archiveCommand)
            if config.verbose {
                print(output)
            }
        } catch {
            throw ArchiveError.archiveFailed(reason: error.localizedDescription)
        }
        
        // Extract archive information
        let archiveInfo = try extractArchiveInfo(archivePath: archivePath)
        
        print("✅ Archive created successfully!")
        print("   Location: \(archivePath)")
        print("   Bundle ID: \(archiveInfo.bundleIdentifier)")
        print("   Version: \(archiveInfo.version) (\(archiveInfo.buildNumber))")
        
        return ArchiveResult(
            archivePath: archivePath,
            bundleIdentifier: archiveInfo.bundleIdentifier,
            version: archiveInfo.version,
            buildNumber: archiveInfo.buildNumber
        )
    }
    
    func exportApp(from archiveResult: ArchiveResult, config: ArchiveConfig) throws -> ExportResult? {
        guard let exportOutputPath = config.exportOutputPath,
              let exportMethod = config.exportMethod else {
            return nil
        }
        
        print("📦 Exporting app (\(exportMethod.description))")
        
        // Ensure export directory exists
        try createDirectoryIfNeeded(exportOutputPath)
        
        // Create export options plist
        let exportOptionsPath = try createExportOptionsPlist(
            exportMethod: exportMethod,
            bundleIdentifier: archiveResult.bundleIdentifier
        )
        
        // Build export command
        let exportCommand = buildExportCommand(
            archivePath: archiveResult.archivePath,
            exportPath: exportOutputPath,
            exportOptionsPath: exportOptionsPath
        )
        
        if config.verbose {
            print("Executing: \(exportCommand)")
        }
        
        // Execute export command
        do {
            let output = try shell.run(exportCommand)
            if config.verbose {
                print(output)
            }
        } catch {
            throw ArchiveError.exportFailed(reason: error.localizedDescription)
        }
        
        // Find exported app
        let exportFolder = try Folder(path: exportOutputPath)
        guard let appFile = exportFolder.files.first(where: { $0.extension == "app" }) else {
            throw ArchiveError.exportFailed(reason: "No .app file found in export directory")
        }
        
        print("✅ App exported successfully!")
        print("   Location: \(appFile.path)")
        print("   Ready for notarization and distribution")
        
        // Clean up temporary export options plist
        try? shell.runAndPrint("rm \"\(exportOptionsPath)\"")
        
        return ExportResult(
            exportPath: exportOutputPath,
            appPath: appFile.path
        )
    }
}


// MARK: - Private Methods
private extension MacOSArchiveBuilder {
    func createDirectoryIfNeeded(_ path: String) throws {
        try shell.runAndPrint("mkdir -p \"\(path)\"")
    }
    
    func buildArchiveCommand(projectType: ProjectType, scheme: String, configuration: BuildConfiguration, archivePath: String) -> String {
        let projectFlag: String
        
        switch projectType {
        case .xcodeproj(let path):
            projectFlag = "-project \"\(path)\""
        case .xcworkspace(let path):
            projectFlag = "-workspace \"\(path)\""
        }
        
        return """
        xcodebuild archive \
        \(projectFlag) \
        -scheme "\(scheme)" \
        -configuration \(configuration.rawValue) \
        -destination "generic/platform=macOS" \
        -archivePath "\(archivePath)" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=NO
        """
    }
    
    func buildExportCommand(archivePath: String, exportPath: String, exportOptionsPath: String) -> String {
        return """
        xcodebuild -exportArchive \
        -archivePath "\(archivePath)" \
        -exportPath "\(exportPath)" \
        -exportOptionsPlist "\(exportOptionsPath)"
        """
    }
    
    func extractArchiveInfo(archivePath: String) throws -> (bundleIdentifier: String, version: String, buildNumber: String) {
        // Read Info.plist from the archive
        let infoPlistPath = "\(archivePath)/Info.plist"
        let plistCommand = "/usr/bin/plutil -convert xml1 -o - \"\(infoPlistPath)\""
        
        let output = try shell.run(plistCommand)
        
        // Parse basic info from plist (simplified parsing)
        let bundleId = extractPlistValue(from: output, key: "CFBundleIdentifier") ?? "Unknown"
        let version = extractPlistValue(from: output, key: "CFBundleShortVersionString") ?? "Unknown"
        let buildNumber = extractPlistValue(from: output, key: "CFBundleVersion") ?? "Unknown"
        
        return (bundleId, version, buildNumber)
    }
    
    func extractPlistValue(from plistContent: String, key: String) -> String? {
        // Simple regex-based parsing for demonstration
        // In a production app, you'd want to use a proper plist parser
        let pattern = "<key>\(key)</key>\\s*<string>([^<]+)</string>"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(plistContent.startIndex..., in: plistContent)
        
        if let match = regex?.firstMatch(in: plistContent, options: [], range: range),
           let valueRange = Range(match.range(at: 1), in: plistContent) {
            return String(plistContent[valueRange])
        }
        
        return nil
    }
    
    func createExportOptionsPlist(exportMethod: ExportMethod, bundleIdentifier: String) throws -> String {
        let tempDir = NSTemporaryDirectory()
        let exportOptionsPath = "\(tempDir)ExportOptions-\(UUID().uuidString).plist"
        
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>method</key>
            <string>\(exportMethod.rawValue)</string>
            <key>teamID</key>
            <string></string>
            <key>uploadBitcode</key>
            <false/>
            <key>uploadSymbols</key>
            <true/>
            <key>compileBitcode</key>
            <false/>
        </dict>
        </plist>
        """
        
        // Write plist to temporary file
        try shell.runAndPrint("echo '\(plistContent)' > \"\(exportOptionsPath)\"")
        
        return exportOptionsPath
    }
}


// MARK: - DateFormatter Extension
private extension DateFormatter {
    static let archiveTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}
