//
//  DeleteFolderMethod.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Files

func deleteFolderContents(_ folder: Folder) {
    for file in folder.files {
        try? file.delete()
    }
    
    for subfolder in folder.subfolders {
        deleteFolderContents(subfolder)
        try? subfolder.delete()
    }
}
