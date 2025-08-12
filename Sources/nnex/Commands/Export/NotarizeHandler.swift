//
//  NotarizeHandler.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Files
import NnexKit
import Foundation
import SwiftPicker

protocol NotarizeHandler {
    func isArchiveNotarized(_ archivePath: String) throws -> Bool
    func notarizeAndStaple(archivePath: String, verbose: Bool) throws
}

struct DefaultNotarizeHandler: NotarizeHandler {
    private let shell: Shell
    private let picker: Picker
    
    init(shell: Shell, picker: Picker) {
        self.shell = shell
        self.picker = picker
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
        
        // First check if keychain profile exists
        try validateNotarizationSetup()
        
        // Submit without --wait to get submission ID
        let submitCommand = "xcrun notarytool submit \"\(appPath)\" --keychain-profile \"notarytool-profile\" --output-format json"
        
        if verbose {
            print("Executing: \(submitCommand)")
        }
        
        let submissionId: String
        do {
            let submitOutput = try shell.run(submitCommand)
            if verbose {
                print(submitOutput)
            }
            
            // Parse submission ID from JSON response
            submissionId = try parseSubmissionId(from: submitOutput)
            print("📋 Submission ID: \(submissionId)")
            print("⏳ Waiting for notarization to complete (this may take 5-30 minutes)...")
        } catch {
            let errorMessage = parseNotarizationError(error.localizedDescription)
            throw ExportError.notarizationFailed(reason: errorMessage)
        }
        
        // Poll for status with progress indicators
        try waitForNotarization(submissionId: submissionId, verbose: verbose)
    }
    
    func parseSubmissionId(from jsonOutput: String) throws -> String {
        // Simple parsing for submission ID - in production you'd use proper JSON parsing
        if let range = jsonOutput.range(of: "\"id\": \"") {
            let remaining = String(jsonOutput[range.upperBound...])
            if let endRange = remaining.range(of: "\"") {
                return String(remaining[..<endRange.lowerBound])
            }
        }
        
        // Fallback to regex parsing
        let pattern = "\"id\"\\s*:\\s*\"([^\"]+)\""
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(jsonOutput.startIndex..., in: jsonOutput)
        
        if let match = regex.firstMatch(in: jsonOutput, range: range),
           let idRange = Range(match.range(at: 1), in: jsonOutput) {
            return String(jsonOutput[idRange])
        }
        
        throw ExportError.notarizationFailed(reason: "Could not parse submission ID from notarytool response")
    }
    
    func waitForNotarization(submissionId: String, verbose: Bool) throws {
        let maxAttempts = 60 // 30 minutes with 30-second intervals
        let pollInterval: UInt32 = 30
        
        for attempt in 1...maxAttempts {
            let statusCommand = "xcrun notarytool info \"\(submissionId)\" --keychain-profile \"notarytool-profile\" --output-format json"
            
            do {
                let statusOutput = try shell.run(statusCommand)
                if verbose {
                    print("Status check \(attempt): \(statusOutput)")
                }
                
                if statusOutput.contains("\"status\": \"Accepted\"") {
                    print("✅ Notarization completed successfully")
                    return
                } else if statusOutput.contains("\"status\": \"Invalid\"") {
                    throw ExportError.notarizationFailed(reason: "App binary is invalid. Check code signing and entitlements.")
                } else if statusOutput.contains("\"status\": \"Rejected\"") {
                    throw ExportError.notarizationFailed(reason: "Notarization was rejected by Apple. Check the app for malware or policy violations.")
                } else if statusOutput.contains("\"status\": \"In Progress\"") {
                    // Show progress indicator
                    let dots = String(repeating: ".", count: attempt % 4)
                    print("⏳ Still processing\(dots) (attempt \(attempt)/\(maxAttempts))")
                }
                
            } catch {
                if attempt == maxAttempts {
                    throw ExportError.notarizationFailed(reason: "Timeout waiting for notarization after 30 minutes")
                }
                print("⚠️  Status check failed, retrying in \(pollInterval) seconds...")
            }
            
            if attempt < maxAttempts {
                sleep(pollInterval)
            }
        }
        
        throw ExportError.notarizationFailed(reason: "Timeout waiting for notarization after 30 minutes")
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
    
    func validateNotarizationSetup() throws {
        // Check if notarytool keychain profile exists
        let checkProfileCommand = "xcrun notarytool list --keychain-profile \"notarytool-profile\""
        
        do {
            let _ = try shell.run(checkProfileCommand)
        } catch {
            // Profile doesn't exist - prompt user to set it up
            try setupNotarizationCredentials()
        }
    }
    
    func setupNotarizationCredentials() throws {
        print("🔐 Notarization credentials not found. Let's set them up using API Key...")
        print("📋 You'll need an App Store Connect API key. Get it from: https://appstoreconnect.apple.com/access/api")
        
        let keyId = try picker.getRequiredInput(
            prompt: "Enter your API Key ID (10-character identifier):"
        )
        
        let issuerId = try picker.getRequiredInput(
            prompt: "Enter your Issuer ID (UUID from App Store Connect):"
        )
        
        let keyPath = try picker.getRequiredInput(
            prompt: "Enter the full path to your AuthKey_\(keyId).p8 file:"
        )
        
        // Validate the key file exists
        guard FileManager.default.fileExists(atPath: keyPath) else {
            throw ExportError.notarizationFailed(reason: "API key file not found at path: \(keyPath)")
        }
        
        print("🔑 Setting up notarization keychain profile with API key...")
        
        let storeCredentialsCommand = "xcrun notarytool store-credentials notarytool-profile --key \"\(keyPath)\" --key-id \"\(keyId)\" --issuer \"\(issuerId)\""
        
        do {
            let output = try shell.run(storeCredentialsCommand)
            print("✅ Notarization credentials stored successfully")
            if output.contains("success") || output.contains("stored") || output.contains("saved") {
                print("✅ Ready for notarization")
            }
        } catch {
            throw ExportError.notarizationFailed(reason: "Failed to store credentials: \(error.localizedDescription)")
        }
    }
    
    func parseNotarizationError(_ errorMessage: String) -> String {
        if errorMessage.contains("No keychain item found") {
            return "Notarization keychain profile 'notarytool-profile' not found. Set up notarization credentials first with: xcrun notarytool store-credentials"
        } else if errorMessage.contains("Invalid") {
            return "Invalid app bundle or code signing issue. Ensure the app is properly signed."
        } else if errorMessage.contains("Network") || errorMessage.contains("connection") {
            return "Network error during notarization. Check your internet connection and try again."
        } else {
            return "Notarization failed: \(errorMessage)"
        }
    }
}