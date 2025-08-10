//
//  ArchiveConfig.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Foundation

// MARK: - ArchiveConfig
struct ArchiveConfig {
    let platform: ArchivePlatform
    let projectPath: String
    let scheme: String
    let configuration: BuildConfiguration
    let archiveOutputPath: String
    let exportOutputPath: String?
    let exportMethod: ExportMethod?
    let verbose: Bool
    let openInFinder: Bool
}

// MARK: - ArchivePlatform
enum ArchivePlatform {
    case macOS
    case iOS
}

// MARK: - BuildConfiguration
enum BuildConfiguration: String, CaseIterable {
    case debug = "Debug"
    case release = "Release"
}

extension BuildConfiguration: CustomStringConvertible {
    var description: String { rawValue }
}

// MARK: - ExportMethod
enum ExportMethod: String, CaseIterable {
    case developerID = "developer-id"
    case development = "development"
    case appStore = "app-store"
}

extension ExportMethod: CustomStringConvertible {
    var description: String {
        switch self {
        case .developerID:
            return "Developer ID (for notarization)"
        case .development:
            return "Development"
        case .appStore:
            return "App Store"
        }
    }
}

// MARK: - ArchiveResult
struct ArchiveResult {
    let archivePath: String
    let bundleIdentifier: String
    let version: String
    let buildNumber: String
}

// MARK: - ExportResult
struct ExportResult {
    let exportPath: String
    let appPath: String
}

// MARK: - ArchiveBuilder Protocol
protocol ArchiveBuilder {
    func archive(config: ArchiveConfig) throws -> ArchiveResult
    func exportApp(from archiveResult: ArchiveResult, config: ArchiveConfig) throws -> ExportResult?
}