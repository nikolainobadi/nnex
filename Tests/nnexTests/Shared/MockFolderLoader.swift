////
////  MockFolderLoader.swift
////  nnex
////
////  Created by Nikolai Nobadi on 3/19/25.
////
//
//import Files
//@testable import nnex
//
//struct MockFolderLoader: FolderLoader {
//    init() {
//        try? Folder.temporary.subfolder(named: "Temporary Folder").delete()
//    }
//    
//    func loadTapListFolder() throws -> Folder {
//        return try Folder.temporary.createSubfolder(named: "Temporary Folder")
//    }
//}
