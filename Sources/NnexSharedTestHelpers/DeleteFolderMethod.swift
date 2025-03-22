//
//  DeleteFolderMethod.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Files

public func deleteFolderContents(_ folder: Folder) {
    for file in folder.files {
        do {
            try file.delete()
        } catch {
            print("could not delete file at path", file.path)
        }
    }
    
    for subfolder in folder.subfolders {
        deleteFolderContents(subfolder)
        
        do {
            try subfolder.delete()
        } catch {
            print("could not delete file at path", subfolder.path)
        }
    }
}
