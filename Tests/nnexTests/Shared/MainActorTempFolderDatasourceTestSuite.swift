//
//  MainActorTempFolderDatasourceTestSuite.swift
//  nnex
//
//  Created by Nikolai Nobadi on 9/9/25.
//

import Foundation
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor
class MainActorTempFolderDatasourceTestSuite {
    let tempFolder: Folder
    let projectFolder: Folder
    
    init(testFolder: TestFolder = .init(name: "nnexTempSubFolder", subFolders: []), projectName: String = "testProject") throws {
        // Ensure SIGPIPE is ignored during tests.
        // By default, Darwin/Linux will terminate a process with exit code 13 if it writes
        // to a closed stdout/stderr pipe. Since our code and tests use `print`, the test
        // runner can crash if its stdout pipe closes (e.g., when output is truncated or piped).
        // Calling `_ignoreSigpipe` installs a global signal handler that ignores SIGPIPE,
        // making `print` harmless in these scenarios.
        _ = _ignoreSigpipe
        
        self.tempFolder = try Folder.temporary.createSubfolder(
            named: "\(UUID().uuidString)_\(testFolder.name)"
        )
        
        try createSubfolders(in: tempFolder, subFolders: testFolder.subFolders)
        
        // Create project folder
        self.projectFolder = try tempFolder.createSubfolder(named: projectName)
    }
    
    deinit {
        deleteFolderContents(tempFolder)
    }
}

// MARK: - Dependencies
struct TestFolder {
    let name: String
    let subFolders: [TestFolder]
}

/// Ensures that SIGPIPE is ignored for the entire test process.
/// Without this, any call to `print` (which writes to stdout) could terminate the test runner
/// if the stdout pipe is closed by the environment (exit code 13).
private let _ignoreSigpipe: Void = { signal(SIGPIPE, SIG_IGN) }()

private func createSubfolders(in folder: Folder, subFolders: [TestFolder]) throws {
    for sub in subFolders {
        let newFolder = try folder.createSubfolder(named: sub.name)
        try createSubfolders(in: newFolder, subFolders: sub.subFolders)
    }
}
