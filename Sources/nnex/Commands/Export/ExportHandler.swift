//
//  ExportHandler.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Files
import NnexKit
import Foundation

protocol ExportHandler {
    func exportApp(archivePath: String, outputPath: String, verbose: Bool) throws
}

struct DefaultExportHandler: ExportHandler {
    private let shell: NnexShell
    
    init(shell: NnexShell) {
        self.shell = shell
    }
}


// MARK: - DefaultExportHandler
extension DefaultExportHandler {
    func exportApp(archivePath: String, outputPath: String, verbose: Bool) throws {
        print("📤 Exporting app...")
        
        // Find the app inside the archive
        let appPath = try findAppInArchive(archivePath)
        
        // Ensure output directory exists
        let outputDir = URL(fileURLWithPath: outputPath).deletingLastPathComponent().path
        _ = try shell.bash("mkdir -p \"\(outputDir)\"")
        
        // Copy the app to the output location
        try copyApp(from: appPath, to: outputPath, verbose: verbose)
        
        print("✅ App exported successfully")
    }
}


// MARK: - Private Methods
private extension DefaultExportHandler {
    func findAppInArchive(_ archivePath: String) throws -> String {
        let productsPath = "\(archivePath)/Products/Applications"
        
        guard let folder = try? Folder(path: productsPath) else {
            throw ExportError.invalidArchive(path: archivePath)
        }
        
        let appFolders = folder.subfolders.filter { $0.name.hasSuffix(".app") }
        
        guard let appFolder = appFolders.first else {
            throw ExportError.noAppFoundInArchive(path: archivePath)
        }
        
        return appFolder.path
    }
    
    func copyApp(from sourcePath: String, to destinationPath: String, verbose: Bool) throws {
        let copyCommand = "cp -R \"\(sourcePath)\" \"\(destinationPath)\""
        
        if verbose {
            print("Executing: \(copyCommand)")
        }
        
        do {
            let output = try shell.bash(copyCommand)
            if verbose && !output.isEmpty {
                print(output)
            }
        } catch {
            throw ExportError.exportFailed(reason: error.localizedDescription)
        }
    }
}
