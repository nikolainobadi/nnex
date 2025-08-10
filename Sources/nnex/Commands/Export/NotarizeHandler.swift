//
//  NotarizeHandler.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Files
import NnexKit
import Foundation

protocol NotarizeHandler {
    func isArchiveNotarized(_ archivePath: String) throws -> Bool
    func notarizeAndStaple(archivePath: String, verbose: Bool) throws
}

struct DefaultNotarizeHandler: NotarizeHandler {
    private let shell: Shell
    
    init(shell: Shell) {
        self.shell = shell
    }
}


// MARK: - DefaultNotarizeHandler
extension DefaultNotarizeHandler {
    func isArchiveNotarized(_ archivePath: String) throws -> Bool {
        // Check if the archive contains a notarized app by looking for ticket
        let appPath = try findAppInArchive(archivePath)
        let checkCommand = "spctl -a -vv \"\(appPath)\""
        
        do {
            let output = try shell.run(checkCommand)
            // If spctl succeeds and mentions notarization, it's notarized
            return output.contains("notarized") || output.contains("accepted")
        } catch {
            // If spctl fails, assume not notarized
            return false
        }
    }
    
    func notarizeAndStaple(archivePath: String, verbose: Bool) throws {
        // Extract app from archive first
        let appPath = try findAppInArchive(archivePath)
        
        print("🔒 Starting notarization process...")
        
        // Notarize the app bundle
        try notarizeApp(appPath: appPath, verbose: verbose)
        
        // Staple the notarization ticket
        try stapleApp(appPath: appPath, verbose: verbose)
    }
}


// MARK: - Private Methods
private extension DefaultNotarizeHandler {
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
    
    func notarizeApp(appPath: String, verbose: Bool) throws {
        print("📝 Submitting app for notarization...")
        
        let notarizeCommand = "xcrun notarytool submit \"\(appPath)\" --keychain-profile \"notarytool-profile\" --wait"
        
        if verbose {
            print("Executing: \(notarizeCommand)")
        }
        
        do {
            let output = try shell.run(notarizeCommand)
            if verbose {
                print(output)
            }
            
            // Check if notarization was successful
            if !output.contains("status: Accepted") {
                throw ExportError.notarizationFailed(reason: "Notarization was not accepted")
            }
            
            print("✅ Notarization completed successfully")
        } catch {
            throw ExportError.notarizationFailed(reason: error.localizedDescription)
        }
    }
    
    func stapleApp(appPath: String, verbose: Bool) throws {
        print("📎 Stapling notarization ticket...")
        
        let stapleCommand = "xcrun stapler staple \"\(appPath)\""
        
        if verbose {
            print("Executing: \(stapleCommand)")
        }
        
        do {
            let output = try shell.run(stapleCommand)
            if verbose {
                print(output)
            }
            print("✅ Stapling completed successfully")
        } catch {
            throw ExportError.staplingFailed(reason: error.localizedDescription)
        }
    }
}