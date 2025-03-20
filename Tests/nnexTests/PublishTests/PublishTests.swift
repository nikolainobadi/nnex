//
//  PublishTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files
import Testing
@testable import nnex

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
struct PublishTests {
    @Test("Publishes a binary to Homebrew and verifies the formula file when passing in path and versionInfo")
    func testPublishCommand() throws {
        let tempFolder = Folder.temporary
        defer {
            try? tempFolder.delete()
        }
        
        let tapName = "testTap"
        let projectName = "testProject"
        let versionNumber = "v1.0.0"
        let projectFolder = try tempFolder.createSubfolder(named: projectName)
        let tapFolder = try tempFolder.createSubfolder(named: "homebrew-\(tapName)")
        let sha256 = "abc123def456"
        let assetURL = "assetURL"
        let factory = MockContextFactory(runResults: [sha256, assetURL])
        let context = try factory.makeContext()
        let tap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "") // TODO: - may need remote path
        let formula = SwiftDataFormula(name: projectName, details: "details", homepage: "homepage", license: "MIT", localProjectPath: projectFolder.path, uploadType: .binary)
        
        try context.saveNewTap(tap, formulas: [formula])
        try runCommand(factory, path: projectFolder.path, version: .version(versionNumber))
        
        let formulaFileContents = try #require(try tempFolder.subfolder(named: "homebrew-\(tapName)").file(named: "\(projectName).rb").readAsString())
        
        print(formulaFileContents)
        print("")
        
        #expect(formulaFileContents.contains(projectName))
        #expect(formulaFileContents.contains(sha256))
        #expect(formulaFileContents.contains(assetURL))
    }
}

// MARK: - Run Command
private extension PublishTests {
    func runCommand(_ factory: MockContextFactory, path: String?, version: ReleaseVersionInfo?) throws {
        var args = ["brew", "publish"]
        
        if let path {
            args.append(contentsOf: ["--path", path])
        }
        
        if let version {
            args.append(contentsOf: ["--version", version.arg])
        }
        
        print(args.joined(separator: " "))
        
        try Nnex.testRun(contextFactory: factory, args: args)
    }
}

extension ReleaseVersionInfo {
    var arg: String {
        switch self {
        case .version(let number):
            return number
        case .increment(let part):
            return part.rawValue
        }
    }
}
