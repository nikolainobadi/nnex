//
//  Nnex+ConvenienceFactoryMethods.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

import NnexKit

extension Nnex {
    static func makeBuildController() -> BuildBinaryController {
        let shell = makeShell()
        let picker = makePicker()
        let fileSystem = makeFileSystem()
        let service = BuildBinaryManager(shell: shell, fileSystem: fileSystem)
        let folderBrowser = contextFactory.makeFolderBrowser(picker: picker, fileSystem: fileSystem)
        
        return .init(
            shell: shell,
            picker: picker,
            fileSystem: fileSystem,
            service: service,
            folderBrowser: folderBrowser
        )
    }
}
