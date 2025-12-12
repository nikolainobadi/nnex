//
//  HomebrewTapService.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

public protocol HomebrewTapService {
    func saveTapListFolderPath(path: String)
    func createNewTap(named name: String, details: String, in parentFolder: any Directory, isPrivate: Bool) throws
}
