//
//  AutoVersionHandlerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/12/25.
//

import Testing
import Foundation
import NnShellTesting
import NnexSharedTestHelpers
@testable import NnexKit

struct AutoVersionHandlerTests {
    private let projectPath = "/test/project"
    private let projectName = "TestProject"
}


// MARK: - Version Detection Tests
extension AutoVersionHandlerTests {
    @Test("Detects version from @main ParsableCommand")
    func detectsVersionFromMainCommand() throws {
        let (sut, _) = makeSUT(mainCommandVersion: "1.2.3")

        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectPath)

        #expect(detectedVersion == "1.2.3")
    }

    @Test("Returns nil when no @main ParsableCommand exists")
    func returnsNilWhenNoMainCommand() throws {
        let (sut, _) = makeSUT(hasMainCommand: false, subCommandVersion: "1.0.0")

        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectPath)

        #expect(detectedVersion == nil)
    }

    @Test("Returns nil when @main ParsableCommand has no version")
    func returnsNilWhenMainCommandHasNoVersion() throws {
        let (sut, _) = makeSUT(mainCommandVersion: nil)

        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectPath)

        #expect(detectedVersion == nil)
    }

    @Test("Detects version with v prefix")
    func detectsVersionWithVPrefix() throws {
        let (sut, _) = makeSUT(mainCommandVersion: "v2.1.0")

        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectPath)

        #expect(detectedVersion == "2.1.0")
    }

    @Test("Ignores non-main ParsableCommand files")
    func ignoresNonMainParsableCommands() throws {
        let (sut, _) = makeSUT(mainCommandVersion: "1.0.0", subCommandVersion: "2.0.0")

        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectPath)

        #expect(detectedVersion == "1.0.0") // Should find main command version, not subcommand
    }

    @Test("Returns nil when Sources directory doesn't exist")
    func returnsNilWhenSourcesDirectoryMissing() throws {
        let (sut, _) = makeSUT(createSourcesDir: false)

        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectPath)

        #expect(detectedVersion == nil)
    }
}


// MARK: - Version Update Tests
extension AutoVersionHandlerTests {
    @Test("Updates version successfully")
    func updatesVersionSuccessfully() throws {
        let (sut, fileSystem) = makeSUT(mainCommandVersion: "1.0.0")

        let success = try sut.updateArgumentParserVersion(projectPath: projectPath, newVersion: "2.0.0")

        #expect(success == true)

        let updatedVersion = try sut.detectArgumentParserVersion(projectPath: projectPath)
        #expect(updatedVersion == "2.0.0")

        // Verify file was written
        let mainFilePath = "\(projectPath)/Sources/\(projectName).swift"
        let updatedContent = try fileSystem.readFile(at: mainFilePath)
        #expect(updatedContent.contains("version: \"2.0.0\""))
    }

    @Test("Preserves file structure when updating version")
    func preservesFileStructureWhenUpdating() throws {
        let (sut, fileSystem) = makeSUT(mainCommandVersion: "1.0.0")

        _ = try sut.updateArgumentParserVersion(projectPath: projectPath, newVersion: "3.0.0")

        let mainFilePath = "\(projectPath)/Sources/\(projectName).swift"
        let updatedContent = try fileSystem.readFile(at: mainFilePath)

        // Verify structure is preserved (contains @main, struct, etc.)
        #expect(updatedContent.contains("@main"))
        #expect(updatedContent.contains("struct \(projectName)"))
        #expect(updatedContent.contains("ParsableCommand"))
        #expect(updatedContent.contains("version: \"3.0.0\""))
        #expect(!updatedContent.contains("version: \"1.0.0\""))
    }

    @Test("Returns false when no main command file exists")
    func returnsFalseWhenNoMainCommandExists() throws {
        let (sut, _) = makeSUT(hasMainCommand: false, subCommandVersion: "1.0.0")

        let success = try sut.updateArgumentParserVersion(projectPath: projectPath, newVersion: "2.0.0")

        #expect(success == false)
    }

    @Test("Returns false when main command has no version configuration")
    func returnsFalseWhenMainCommandHasNoVersion() throws {
        let (sut, _) = makeSUT(mainCommandVersion: nil)

        let success = try sut.updateArgumentParserVersion(projectPath: projectPath, newVersion: "2.0.0")

        #expect(success == false)
    }
}


// MARK: - Version Comparison Tests
extension AutoVersionHandlerTests {
    @Test("Detects when versions are different")
    func detectsWhenVersionsAreDifferent() throws {
        let (sut, _) = makeSUT()

        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "1.1.0") == true)
        #expect(sut.shouldUpdateVersion(currentVersion: "v1.0.0", releaseVersion: "1.1.0") == true)
        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "v1.1.0") == true)
    }

    @Test("Detects when versions are the same")
    func detectsWhenVersionsAreTheSame() throws {
        let (sut, _) = makeSUT()

        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "1.0.0") == false)
        #expect(sut.shouldUpdateVersion(currentVersion: "v1.0.0", releaseVersion: "1.0.0") == false)
        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "v1.0.0") == false)
        #expect(sut.shouldUpdateVersion(currentVersion: "v1.0.0", releaseVersion: "v1.0.0") == false)
    }

    @Test("Handles various version formats")
    func handlesVariousVersionFormats() throws {
        let (sut, _) = makeSUT()

        // Different patch versions
        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "1.0.1") == true)

        // Major version differences
        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0", releaseVersion: "2.0.0") == true)

        // Pre-release versions
        #expect(sut.shouldUpdateVersion(currentVersion: "1.0.0-beta", releaseVersion: "1.0.0") == true)
    }
}


// MARK: - Edge Cases Tests
extension AutoVersionHandlerTests {
    @Test("Handles multiple CommandConfiguration blocks")
    func handlesMultipleCommandConfigurations() throws {
        let (sut, _) = makeSUT(complexMainCommand: true)

        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectPath)

        #expect(detectedVersion == "1.5.0") // Should find the main command version
    }

    @Test("Handles malformed version strings gracefully")
    func handlesMalformedVersionStrings() throws {
        let (sut, _) = makeSUT(malformedVersion: true)

        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectPath)

        #expect(detectedVersion == nil)
    }

    @Test("Handles files in subdirectories", .disabled())
    func handlesFilesInSubdirectories() throws {
        let (sut, _) = makeSUT(mainCommandVersion: "2.5.0", inSubdirectory: true)

        let detectedVersion = try sut.detectArgumentParserVersion(projectPath: projectPath)

        #expect(detectedVersion == "2.5.0")
    }
}


// MARK: - SUT & Helpers
private extension AutoVersionHandlerTests {
    func makeSUT(
        mainCommandVersion: String? = "1.0.0",
        hasMainCommand: Bool = true,
        subCommandVersion: String? = nil,
        createSourcesDir: Bool = true,
        complexMainCommand: Bool = false,
        malformedVersion: Bool = false,
        inSubdirectory: Bool = false
    ) -> (sut: AutoVersionHandler, fileSystem: MockFileSystem) {
        let shell = MockShell()

        // Create directory structure
        var sourcesDir: MockDirectory?
        var subdirectories: [any Directory] = []

        if createSourcesDir {
            if inSubdirectory {
                // Create Commands subdirectory
                let commandsDir = MockDirectory(path: "\(projectPath)/Sources/Commands")
                let mainFilePath = "Main.swift"
                let content = createMainCommandContent(version: mainCommandVersion)
                commandsDir.fileContents[mainFilePath] = content
                commandsDir.containedFiles.insert(mainFilePath)

                sourcesDir = MockDirectory(path: "\(projectPath)/Sources", subdirectories: [commandsDir])
            } else {
                sourcesDir = MockDirectory(path: "\(projectPath)/Sources")

                // Add main command file if needed
                if hasMainCommand {
                    let mainFilePath = "\(projectName).swift"
                    let content: String

                    if complexMainCommand {
                        content = createComplexMainCommandContent()
                    } else if malformedVersion {
                        content = createMalformedVersionContent()
                    } else {
                        content = createMainCommandContent(version: mainCommandVersion)
                    }

                    sourcesDir!.fileContents[mainFilePath] = content
                    sourcesDir!.containedFiles.insert(mainFilePath)
                }

                // Add subcommand file if needed
                if let subVersion = subCommandVersion {
                    let subFilePath = "SubCommand.swift"
                    let subContent = createSubCommandContent(version: subVersion)
                    sourcesDir!.fileContents[subFilePath] = subContent
                    sourcesDir!.containedFiles.insert(subFilePath)
                }
            }

            subdirectories.append(sourcesDir!)
        }

        let projectDir = MockDirectory(path: projectPath, subdirectories: subdirectories)

        var directoryMap: [String: any Directory] = [projectPath: projectDir]
        if let sources = sourcesDir {
            directoryMap["\(projectPath)/Sources"] = sources
        }

        let fileSystem = MockFileSystem(directoryMap: directoryMap)

        let sut = AutoVersionHandler(shell: shell, fileSystem: fileSystem)
        return (sut, fileSystem)
    }

    func createMainCommandContent(version: String?) -> String {
        let versionLine = version.map { "version: \"\($0)\"," } ?? ""
        return """
        //
        //  \(projectName).swift
        //  \(projectName)
        //

        import ArgumentParser

        @main
        struct \(projectName): ParsableCommand {
            static let configuration = CommandConfiguration(
                abstract: "Test command line tool",
                \(versionLine)
                subcommands: []
            )

            func run() throws {
                print("Hello, World!")
            }
        }
        """
    }

    func createSubCommandContent(version: String) -> String {
        return """
        import ArgumentParser

        struct SubCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                abstract: "Sub command",
                version: "\(version)"
            )

            func run() throws {
                print("Sub command")
            }
        }
        """
    }

    func createComplexMainCommandContent() -> String {
        return """
        import ArgumentParser

        @main
        struct \(projectName): ParsableCommand {
            static let configuration = CommandConfiguration(
                abstract: "Complex command",
                version: "1.5.0",
                subcommands: [SubCommand.self]
            )
        }

        struct SubCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                abstract: "Sub command",
                version: "2.0.0"
            )
        }
        """
    }

    func createMalformedVersionContent() -> String {
        return """
        import ArgumentParser

        @main
        struct \(projectName): ParsableCommand {
            static let configuration = CommandConfiguration(
                abstract: "Malformed version command",
                version: someVariable
            )
        }
        """
    }
}
