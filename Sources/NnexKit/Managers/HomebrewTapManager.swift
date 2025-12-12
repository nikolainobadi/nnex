//
//  HomebrewTapManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import Foundation

public struct HomebrewTapManager {
    private let shell: any NnexShell
    private let store: any HomebrewTapStore
    private let gitHandler: any GitHandler
    
    public init(shell: any NnexShell, store: any HomebrewTapStore, gitHandler: any GitHandler) {
        self.shell = shell
        self.store = store
        self.gitHandler = gitHandler
    }
}


// MARK: - HomebrewTapService
extension HomebrewTapManager: HomebrewTapService {
    public func saveTapListFolderPath(path: String) {
        store.saveTapListFolderPath(path: path)
    }
    
    public func createNewTap(named name: String, details: String, in parentFolder: any Directory, isPrivate: Bool) throws {
        try gitHandler.ghVerification()
        
        let tapFolder = try createTapFolder(named: name, in: parentFolder)
        let remotePath = try createRemoteRepository(folder: tapFolder, details: details, isPrivate: isPrivate)
        
        try store.saveNewTap(.init(folder: tapFolder, remotePath: remotePath), formulas: [])
    }
    
    public func importTap(from folder: any Directory) throws -> HomebrewTapImportResult {
        try gitHandler.ghVerification()
        
        let (tap, warnings) = try makeTap(from: folder)
        
        try store.saveNewTap(tap, formulas: tap.formulas)
        
        return .init(tap: tap, warnings: warnings)
    }
}


// MARK: - Private Methods
private extension HomebrewTapManager {
    func createTapFolder(named name: String, in parentFolder: any Directory) throws -> any Directory {
        let homebrewTapName = name.homebrewTapName
        let tapFolder = try parentFolder.createSubfolderIfNeeded(named: homebrewTapName)
        
        _ = try tapFolder.createSubfolderIfNeeded(named: "Formula")
        
        return tapFolder
    }
    
    func createRemoteRepository(folder: any Directory, details: String, isPrivate: Bool) throws -> String {
        let path = folder.path
        try gitHandler.gitInit(path: path)
        return try gitHandler.remoteRepoInit(tapName: folder.name, path: path, projectDetails: details, visibility: isPrivate ? .privateRepo : .publicRepo)
    }
    
    func makeTap(from folder: any Directory) throws -> (HomebrewTap, [String]) {
        let decoder = HomebrewFormulaDecoder(shell: shell)
        let tapName = folder.name.removingHomebrewPrefix
        let remotePath = try gitHandler.getRemoteURL(path: folder.path)
        let (formulas, warnings) = try decoder.decodeFormulas(in: folder)
        
        return (.init(name: tapName, localPath: folder.path, remotePath: remotePath, formulas: formulas), warnings)
    }
}


// MARK: - Dependencies
public protocol HomebrewTapStore {
    func saveTapListFolderPath(path: String)
    func saveNewTap(_ tap: HomebrewTap, formulas: [HomebrewFormula]) throws
}


// MARK: - Extension Dependencies
private extension HomebrewTap {
    init(folder: any Directory, remotePath: String, formulas: [HomebrewFormula] = []) {
        self.init(name: folder.name, localPath: folder.path, remotePath: remotePath, formulas: formulas)
    }
}
