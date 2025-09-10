//
//  TempFolderTestSuiteTemplate.swift
//  nnex
//
//  Created by Nikolai Nobadi on 9/10/25.
//

import Foundation
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor
class TempFolderTestSuiteTemplate<Config: TestFolderConfiguration> {
    let folders: Config
    
    var tempFolder: Folder {
        return folders.tempFolder
    }
    
    init(folders: Config) {
        _ = _ignoreSigpipe
        self.folders = folders
    }
    
    deinit {
        deleteFolderContents(folders.tempFolder)
        try? folders.tempFolder.delete()
    }
}

extension TempFolderTestSuiteTemplate {
    static func makeTempFolder(name: String) throws -> Folder {
        return try Folder.temporary.createSubfolder(named: "\(UUID().uuidString)_\(name)")
    }
}

@MainActor
class BaseTempFolderTestSuite: TempFolderTestSuiteTemplate<BaseFolderConfig> {
    init(name: String) throws {
        try super.init(folders: .init(tempFolder: Self.makeTempFolder(name: name)))
    }
}


/// Ensures that SIGPIPE is ignored for the entire test process.
/// Without this, any call to `print` (which writes to stdout) could terminate the test runner
/// if the stdout pipe is closed by the environment (exit code 13).
private let _ignoreSigpipe: Void = { signal(SIGPIPE, SIG_IGN) }()

protocol TestFolderConfiguration: Sendable {
    var tempFolder: Folder { get }
}

struct BaseFolderConfig: TestFolderConfiguration {
    let tempFolder: Folder
}
