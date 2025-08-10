//
//  ArchiveIOS.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import ArgumentParser

extension Nnex.Archive {
    struct IOS: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "ios",
            abstract: "Archive an iOS application."
        )
        
        func run() throws {
            print("📱 iOS archiving is not yet implemented.")
            print("💡 This feature is planned for a future release.")
            print("🔄 For now, use Xcode or xcodebuild directly for iOS archiving.")
        }
    }
}