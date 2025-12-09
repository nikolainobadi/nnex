////
////  AutoVersionHandlerTests.swift
////  nnex
////
////  Created by Nikolai Nobadi on 8/12/25.
////
//
//import Testing
//import Foundation
//import NnShellKit
//import NnexSharedTestHelpers
//@testable import NnexKit
//@preconcurrency import Files
//
//@MainActor
//final class AutoVersionHandlerTests {
//    private let projectFolder: Folder
//    private let projectName = "TestProject"
//    
//    init() throws {
//        let tempFolder = Folder.temporary
//        self.projectFolder = try tempFolder.createSubfolder(named: "AutoVersionHandler-\(UUID().uuidString)")
//    }
//    
//    deinit {
//        deleteFolderContents(projectFolder)
//    }
//}
//
//
//// MARK: - Version Detection Tests
//extension AutoVersionHandlerTests {
//    @Test("Detects version from @main ParsableCommand")
//    func detectsVersionFromMainCommand() throws {
//        try createMainCommandFile(version: "1.2.3")
//        
//        let sut = makeSUT()
//        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectFolder.path)
//        
//        #expect(detectedVersion == "1.2.3")
//    }
//    
//    @Test("Returns nil when no @main ParsableCommand exists")
//    func returnsNilWhenNoMainCommand() throws {
//        try createNonMainCommandFiles(version: "1.0.0")
//        
//        let sut = makeSUT()
//        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectFolder.path)
//        
//        #expect(detectedVersion == nil)
//    }
//    
//    @Test("Returns nil when @main ParsableCommand has no version")
//    func returnsNilWhenMainCommandHasNoVersion() throws {
//        try createMainCommandFileWithoutVersion()
//        
//        let sut = makeSUT()
//        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectFolder.path)
//        
//        #expect(detectedVersion == nil)
//    }
//    
//    @Test("Detects version with v prefix")
//    func detectsVersionWithVPrefix() throws {
//        try createMainCommandFile(version: "v2.1.0")
//        
//        let sut = makeSUT()
//        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectFolder.path)
//        
//        #expect(detectedVersion == "2.1.0")
//    }
//    
//    @Test("Ignores non-main ParsableCommand files")
//    func ignoresNonMainParsableCommands() throws {
//        try createMainCommandFile(version: "1.0.0")
//        try createNonMainCommandFiles(version: "2.0.0")
//        
//        let sut = makeSUT()
//        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectFolder.path)
//        
//        #expect(detectedVersion == "1.0.0") // Should find main command version, not subcommand
//    }
//    
//    @Test("Returns nil when Sources directory doesn't exist")
//    func returnsNilWhenSourcesDirectoryMissing() throws {
//        let sut = makeSUT()
//        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectFolder.path)
//        
//        #expect(detectedVersion == nil)
//    }
//}
//
//
//// MARK: - Version Update Tests
//extension AutoVersionHandlerTests {
//    @Test("Updates version successfully")
//    func updatesVersionSuccessfully() throws {
//        try createMainCommandFile(version: "1.0.0")
//        
//        let sut = makeSUT()
//        let success = try sut.updateArgumentParserVersion(projectPath: projectFolder.path, newVersion: "2.0.0")
//        
//        #expect(success == true)
//        
//        let updatedVersion = try sut.detectArgumentParserVersion(projectPath: projectFolder.path)
//        #expect(updatedVersion == "2.0.0")
//    }
//    
//    @Test("Preserves file structure when updating version")
//    func preservesFileStructureWhenUpdating() throws {
//        _ = try createMainCommandFile(version: "1.0.0")
//        
//        let sut = makeSUT()
//        _ = try sut.updateArgumentParserVersion(projectPath: projectFolder.path, newVersion: "3.0.0")
//        
//        let sourcesPath = projectFolder.path + "/Sources"
//        let mainFile = try Folder(path: sourcesPath).files.recursive.first { $0.extension == "swift" }
//        let updatedContent = try mainFile?.readAsString()
//        
//        // Verify structure is preserved (contains @main, struct, etc.)
//        #expect(updatedContent?.contains("@main") == true)
//        #expect(updatedContent?.contains("struct \(projectName)") == true)
//        #expect(updatedContent?.contains("ParsableCommand") == true)
//        #expect(updatedContent?.contains("version: \"3.0.0\"") == true)
//        #expect(updatedContent?.contains("version: \"1.0.0\"") == false)
//    }
//    
//    @Test("Returns false when no main command file exists")
//    func returnsFalseWhenNoMainCommandExists() throws {
//        try createNonMainCommandFiles(version: "1.0.0")
//        
//        let sut = makeSUT()
//        let success = try sut.updateArgumentParserVersion(projectPath: projectFolder.path, newVersion: "2.0.0")
//        
//        #expect(success == false)
//    }
//    
//    @Test("Returns false when main command has no version configuration")
//    func returnsFalseWhenMainCommandHasNoVersion() throws {
//        try createMainCommandFileWithoutVersion()
//        
//        let sut = makeSUT()
//        let success = try sut.updateArgumentParserVersion(projectPath: projectFolder.path, newVersion: "2.0.0")
//        
//        #expect(success == false)
//    }
//}
//
//
//// MARK: - Version Comparison Tests
//extension AutoVersionHandlerTests {
//    @Test("Detects when versions are different")
//    func detectsWhenVersionsAreDifferent() throws {
//        let sut = makeSUT()
//        
//        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "1.1.0") == true)
//        #expect(sut.shouldUpdateVersion(currentVersion: "v1.0.0", releaseVersion: "1.1.0") == true)
//        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "v1.1.0") == true)
//    }
//    
//    @Test("Detects when versions are the same")
//    func detectsWhenVersionsAreTheSame() throws {
//        let sut = makeSUT()
//        
//        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "1.0.0") == false)
//        #expect(sut.shouldUpdateVersion(currentVersion: "v1.0.0", releaseVersion: "1.0.0") == false)
//        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "v1.0.0") == false)
//        #expect(sut.shouldUpdateVersion(currentVersion: "v1.0.0", releaseVersion: "v1.0.0") == false)
//    }
//    
//    @Test("Handles various version formats")
//    func handlesVariousVersionFormats() throws {
//        let sut = makeSUT()
//        
//        // Different patch versions
//        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "1.0.1") == true)
//        
//        // Major version differences
//        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "2.0.0") == true)
//        
//        // Pre-release versions
//        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0-beta", releaseVersion: "1.0.0") == true)
//    }
//}
//
//
//// MARK: - Edge Cases Tests
//extension AutoVersionHandlerTests {
//    @Test("Handles multiple CommandConfiguration blocks")
//    func handlesMultipleCommandConfigurations() throws {
//        try createComplexMainCommandFile()
//        
//        let sut = makeSUT()
//        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectFolder.path)
//        
//        #expect(detectedVersion == "1.5.0") // Should find the main command version
//    }
//    
//    @Test("Handles malformed version strings gracefully")
//    func handlesMalformedVersionStrings() throws {
//        try createMainCommandFileWithMalformedVersion()
//        
//        let sut = makeSUT()
//        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectFolder.path)
//        
//        #expect(detectedVersion == nil)
//    }
//    
//    @Test("Handles files in subdirectories")
//    func handlesFilesInSubdirectories() throws {
//        try createMainCommandFileInSubdirectory(version: "2.5.0")
//        
//        let sut = makeSUT()
//        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectFolder.path)
//        
//        #expect(detectedVersion == "2.5.0")
//    }
//}
//
//
//// MARK: - SUT & Helpers
//private extension AutoVersionHandlerTests {
//    func makeSUT() -> AutoVersionHandler {
//        let shell = MockShell()
//        return AutoVersionHandler(shell: shell)
//    }
//    
//    @discardableResult
//    func createMainCommandFile(version: String) throws -> String {
//        let sourcesFolder = try projectFolder.createSubfolder(named: "Sources")
//        let content = """
//        //
//        //  \(projectName).swift
//        //  \(projectName)
//        //
//        
//        import ArgumentParser
//        
//        @main
//        struct \(projectName): ParsableCommand {
//            static let configuration = CommandConfiguration(
//                abstract: "Test command line tool",
//                version: "\(version)",
//                subcommands: []
//            )
//            
//            func run() throws {
//                print("Hello, World!")
//            }
//        }
//        """
//        
//        try sourcesFolder.createFile(named: "\(projectName).swift", contents: content.data(using: .utf8)!)
//        return content
//    }
//    
//    func createNonMainCommandFiles(version: String) throws {
//        let sourcesFolder = try projectFolder.createSubfolder(named: "Sources")
//        let content = """
//        import ArgumentParser
//        
//        struct SubCommand: ParsableCommand {
//            static let configuration = CommandConfiguration(
//                abstract: "Sub command",
//                version: "\(version)"
//            )
//            
//            func run() throws {
//                print("Sub command")
//            }
//        }
//        """
//        
//        try sourcesFolder.createFile(named: "SubCommand.swift", contents: content.data(using: .utf8)!)
//        
//        let otherContent = """
//        import ArgumentParser
//        
//        /// Finds the main command file containing @main ParsableCommand.
//        
//        """
//        
//        try sourcesFolder.createFile(named: "Random.swift", contents: otherContent.data(using: .utf8)!)
//    }
//    
//    func createMainCommandFileWithoutVersion() throws {
//        let sourcesFolder = try projectFolder.createSubfolder(named: "Sources")
//        let content = """
//        import ArgumentParser
//        
//        @main
//        struct \(projectName): ParsableCommand {
//            static let configuration = CommandConfiguration(
//                abstract: "Test command without version"
//            )
//            
//            func run() throws {
//                print("Hello, World!")
//            }
//        }
//        """
//        
//        try sourcesFolder.createFile(named: "\(projectName).swift", contents: content.data(using: .utf8)!)
//    }
//    
//    func createComplexMainCommandFile() throws {
//        let sourcesFolder = try projectFolder.createSubfolder(named: "Sources")
//        let content = """
//        import ArgumentParser
//        
//        @main
//        struct \(projectName): ParsableCommand {
//            static let configuration = CommandConfiguration(
//                abstract: "Complex command",
//                version: "1.5.0",
//                subcommands: [SubCommand.self]
//            )
//        }
//        
//        struct SubCommand: ParsableCommand {
//            static let configuration = CommandConfiguration(
//                abstract: "Sub command",
//                version: "2.0.0"
//            )
//        }
//        """
//        
//        try sourcesFolder.createFile(named: "\(projectName).swift", contents: content.data(using: .utf8)!)
//    }
//    
//    func createMainCommandFileWithMalformedVersion() throws {
//        let sourcesFolder = try projectFolder.createSubfolder(named: "Sources")
//        let content = """
//        import ArgumentParser
//        
//        @main
//        struct \(projectName): ParsableCommand {
//            static let configuration = CommandConfiguration(
//                abstract: "Malformed version command",
//                version: someVariable
//            )
//        }
//        """
//        
//        try sourcesFolder.createFile(named: "\(projectName).swift", contents: content.data(using: .utf8)!)
//    }
//    
//    func createMainCommandFileInSubdirectory(version: String) throws {
//        let sourcesFolder = try projectFolder.createSubfolder(named: "Sources")
//        let commandsFolder = try sourcesFolder.createSubfolder(named: "Commands")
//        let content = """
//        import ArgumentParser
//        
//        @main
//        struct \(projectName): ParsableCommand {
//            static let configuration = CommandConfiguration(
//                abstract: "Command in subdirectory",
//                version: "\(version)"
//            )
//        }
//        """
//        
//        try commandsFolder.createFile(named: "Main.swift", contents: content.data(using: .utf8)!)
//    }
//}
