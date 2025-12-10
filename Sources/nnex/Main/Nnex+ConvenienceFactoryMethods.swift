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
        let service = FakeService() // TODO: -
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

struct FakeService: BuildBinaryService {
    func build(config: NnexKit.BuildConfig) throws -> NnexKit.BinaryOutput {
        fatalError()
    }
    
    func getExecutableNames(from directory: any NnexKit.Directory) throws -> [String] {
        fatalError()
    }
    
    func moveBinary(_ binary: NnexKit.BinaryOutput, to location: NnexKit.BuildOutputLocation) throws -> NnexKit.BinaryOutput {
        fatalError()
    }
}
