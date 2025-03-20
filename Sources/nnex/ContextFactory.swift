//
//  ContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import SwiftPicker

protocol FolderLoader {
    func loadTapListFolder() throws -> Folder
}

protocol ContextFactory {
    func makePicker() -> Picker
    func makeBuilder() -> ProjectBuilder
    func makeFolderLoader() -> FolderLoader
    func makeContext() throws -> SharedContext
    func makeRemoteRepoLoader() -> RemoteRepoLoader
}

protocol Picker {
    func getPermission(_ type: PermissionType) -> Bool
    func getRequiredInput(_ type: InputType) throws -> String
    func requiredSingleSelection<Item: DisplayablePickerItem>(title: String, items: [Item]) throws -> Item
}

enum PermissionType {
    case doesTapAlreadyExist
}

extension PermissionType {
    var prompt: String {
        switch self {
        case .doesTapAlreadyExist:
            return "Does the folder for this tap alreay exist on your computer?"
        }
    }
}

enum InputType {
    case newTap, importTapPath
}

extension InputType {
    var prompt: String {
        switch self {
        case .newTap:
            return "Enter the name of your new Homebrew Tap."
        case .importTapPath:
            return "Enter the local path to you Homebrew tap folder."
        }
    }
}


// MARK: - Default Factory
struct DefaultContextFactory: ContextFactory {
    func makePicker() -> any Picker {
        return DefaultPicker()
    }
    
    func makeFolderLoader() -> any FolderLoader {
        return DefaultFolderLoader()
    }
    
    func makeBuilder() -> ProjectBuilder {
        return DefaultProjectBuilder()
    }
    
    func makeContext() throws -> SharedContext {
        return try SharedContext()
    }
    
    func makeRemoteRepoLoader() -> RemoteRepoLoader {
        return DefaultRemoteRepoLoader()
    }
}


// TODO: - 
struct DefaultFolderLoader: FolderLoader {
    func loadTapListFolder() throws -> Folder {
        return try Folder.home.subfolder(named: "Desktop")
    }
}
