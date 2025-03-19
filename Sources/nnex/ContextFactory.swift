//
//  ContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files

protocol FolderLoader {
    func loadTapListFolder() throws -> Folder
}

protocol ContextFactory {
    func makePicker() -> Picker
    func makeFolderLoader() -> FolderLoader
    func makeContext() throws -> SharedContext
}

protocol Picker {
    func getRequiredInput(_ type: InputType) throws -> String
}

enum InputType {
    case newTap
}

extension InputType {
    var prompt: String {
        switch self {
        case .newTap:
            return "Enter the name of your new Homebrew Tap."
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
    
    func makeContext() throws -> SharedContext {
        return try SharedContext()
    }
}

import SwiftPicker

struct DefaultPicker {
    private let picker = SwiftPicker()
}

extension DefaultPicker: Picker {
    func getRequiredInput(_ type: InputType) throws -> String {
        return try picker.getRequiredInput(type.prompt)
    }
}

// TODO: - 
struct DefaultFolderLoader: FolderLoader {
    func loadTapListFolder() throws -> Folder {
        return try Folder.home.subfolder(named: "Desktop")
    }
}
