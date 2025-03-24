//
//  Config.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import NnexKit
import ArgumentParser

extension Nnex {
    struct Config: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Manage configuration settings for Nnex.",
            subcommands: [
                SetListPath.self, ShowListPath.self, OpenListFolder.self,
                SetBuildType.self, ShowBuildType.self
            ]
        )
    }
}


// MARK: - SetTapFolder
extension Nnex.Config {
    struct SetListPath: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Sets the path the the folder where new taps will be created")
        
        @Option(name: .shortAndLong, help: "The path to the folder where new Homebrew Taps should be saved.")
        var path: String?
        
        func run() throws {
            let path = try path ?? Nnex.makePicker().getRequiredInput(prompt: "Enter the path to the folder where you want new taps to be created.")
            let context = try Nnex.makeContext()
            
            context.saveTapListFolderPath(path: path)
        }
    }
}


// MARK: - ShowTapFolder
extension Nnex.Config {
    struct ShowListPath: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Displays the current path to the folder where new taps will be created.")

        func run() throws {
            let context = try Nnex.makeContext()
            
            if let path = context.loadTapListFolderPath() {
                print("Current Tap Folder Path: \(path)")
            } else {
                print("No tap folder path has been set.")
            }
        }
    }
}


// MARK: - OpenTapFolder
extension Nnex.Config {
    struct OpenListFolder: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Opens the current tap folder in Finder.")

        func run() throws {
            let context = try Nnex.makeContext()
            
            guard let path = context.loadTapListFolderPath() else {
                print("No tap folder path has been set.")
                return
            }

            try Nnex.makeShell().runAndPrint("open \(path)")
        }
    }
}


// MARK: - SetBuildType
extension Nnex.Config {
    struct SetBuildType: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Sets the default binary build type.")
        
        @Argument(help: "The build type to set. Options: \(BuildType.allCases.map(\.rawValue).joined(separator: ", "))")
        var buildType: BuildType?
        
        func run() throws {
            let context = try Nnex.makeContext()
            let buildType = try buildType ?? Nnex.makePicker().requiredSingleSelection(title: "Select a build type.", items: BuildType.allCases)
            
            context.saveDefaultBuildType(buildType)
            print("Default build type set to: \(buildType.rawValue)")
        }
    }
}


// MARK: - ShowBuildType
extension Nnex.Config {
    struct ShowBuildType: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Displays the current default binary build type.")

        func run() throws {
            let context = try Nnex.makeContext()
            let buildType = context.loadDefaultBuildType()
            print("Current Default Build Type: \(buildType.rawValue)")
        }
    }
}
