////
////  ReleaseVersionHandlerIntegrationTests.swift
////  nnex
////
////  Created by Nikolai Nobadi on 8/16/25.
////
//
//import Testing
//import Foundation
//import NnShellKit
//import SwiftPickerTesting
//import NnexSharedTestHelpers
//@testable import nnex
//@preconcurrency import Files
//
//final class ReleaseVersionHandlerIntegrationTests {
//    private let oldVersion: String
//    private let newVersion = "2.0.0"
//    private let projectFolder: Folder
//    private let projectName = "TestProject"
//    private let mainCommandFilePath: String
//    
//    init() throws {
//        oldVersion = "1.0.0"
//        projectFolder = try Folder.temporary.createSubfolder(named: "AutoVersionHandler-\(UUID().uuidString)")
//        mainCommandFilePath = try createMockCommandFile(previousVersion: oldVersion, projectFolder: projectFolder)
//    }
//    
//    deinit {
//        deleteFolderContents(projectFolder)
//    }
//}
//
//
//// MARK: - Tests
//extension ReleaseVersionHandlerIntegrationTests {
//    @Test("Updates source code version if it exists")
//    func updatesExistingVersionInSource() throws {
//        let sut = makeSUT().sut
//        let _ = try sut.resolveVersionInfo(versionInfo: .version(newVersion), projectPath: projectFolder.path)
//        let updatedFile = try File(path: mainCommandFilePath)
//        let contents = try updatedFile.readAsString()
//        
//        #expect(contents.contains(newVersion), "File should contain version 2.0.0")
//    }
//    
//    @Test("Commits changes to source code when updating version number in executable file")
//    func commitsNewVersionInSource() throws {
//        let (sut, gitHandler) = makeSUT()
//        let _ = try sut.resolveVersionInfo(versionInfo: .version(newVersion), projectPath: projectFolder.path)
//        let message = try #require(gitHandler.message)
//        let expectedMessage = "Update version to \(newVersion)"
//        
//        #expect(message == expectedMessage)
//    }
//}
//
//
//// MARK: - SUT
//private extension ReleaseVersionHandlerIntegrationTests {
//    func makeSUT(previousVersion: String? = nil) -> (sut: ReleaseVersionHandler, gitHandler: MockGitHandler) {
//        let shell = MockShell()
//        let picker = MockSwiftPicker(permissionResult: .init(defaultValue: true))
//        let gitHandler = makeGitHandler(previousVersion: previousVersion, throwError: false)
//        let sut = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler, shell: shell)
//        
//        return (sut, gitHandler)
//    }
//    
//    func makeGitHandler(previousVersion: String?, throwError: Bool) -> MockGitHandler {
//        if let previousVersion {
//            return .init(previousVersion: previousVersion, throwError: throwError)
//        }
//        
//        return .init(previousVersion: "", throwError: throwError)
//    }
//}
//
//
//// MARK: - Private Helpers
//private func createMockCommandFile(previousVersion: String, projectFolder: Folder) throws -> String {
//    let fileContents = """
//    import ArgumentParser
//
//    @main
//    struct MockCommand: ParsableCommand {
//        static let configuration = CommandConfiguration(
//            abstract: "",
//            version: "\(previousVersion)",
//        )
//    }
//    """
//
//    let file = try projectFolder.createSubfolderIfNeeded(withName: "Sources").createFile(named: "MockCommand.swift")
//    try file.write(fileContents)
//
//    return file.path
//}
