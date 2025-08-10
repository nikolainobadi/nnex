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
    let verbose: Bool
    let openInFinder: Bool
    let universalBinary: Bool
    let stripBinary: Bool
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


// MARK: - ArchiveResult
struct ArchiveResult {
    let archivePath: String
    let bundleIdentifier: String
    let version: String
    let buildNumber: String
}

// MARK: - ArchiveBuilder Protocol
protocol ArchiveBuilder {
    func archive(config: ArchiveConfig) throws -> ArchiveResult
}