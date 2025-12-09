////
////  ProjectDetectorTests.swift
////  nnex
////
////  Created by Claude Code on 8/10/25.
////
//
//import Testing
//import Foundation
//import NnexKit
//import NnShellKit
//import NnexSharedTestHelpers
//@testable import nnex
//@preconcurrency import Files
//
//@MainActor
//final class ProjectDetectorTests: BaseTempFolderTestSuite {
//    private let testProjectPath = "/test/project"
//    private let testProjectName = "TestApp"
//    private let testWorkspacePath = "/test/project/TestApp.xcworkspace"
//    private let testXcodeprojPath = "/test/project/TestApp.xcodeproj"
//    private let testSchemes = ["TestApp", "TestApp-macOS", "TestApp-iOS"]
//    private let xcodebuildListOutput = """
//    Information about project "TestApp":
//        Targets:
//            TestApp
//            TestApp macOS
//            TestApp iOS
//        
//        Build Configurations:
//            Debug
//            Release
//        
//        If no build configuration is specified and -scheme is not passed then "Release" is used.
//        
//        Schemes:
//            TestApp
//            TestApp-macOS
//            TestApp-iOS
//    """
//    
//    init() throws {
//        try super.init(name: "ProjectDetectorTestProject")
//    }
//}
//
//
//// MARK: - Unit Tests
//extension ProjectDetectorTests {
//    @Test("Detects workspace when both workspace and project exist")
//    func detectsWorkspaceWhenBothExist() throws {
//        let sut = makeSUT()
//        
//        // Create both workspace and project files
//        try tempFolder.createFile(named: "TestApp.xcworkspace")
//        try tempFolder.createSubfolder(named: "TestApp.xcodeproj")
//        
//        let result = try sut.detectProject(at: tempFolder.path)
//        
//        #expect(result.type.path.contains("TestApp.xcworkspace"))
//        #expect(result.name == "TestApp")
//        #expect(result.supportedPlatforms.contains(.macOS))
//        #expect(result.supportedPlatforms.contains(.iOS))
//    }
//    
//    @Test("Detects project when only xcodeproj exists")
//    func detectsProjectWhenOnlyXcodeprojExists() throws {
//        let sut = makeSUT()
//        
//        try tempFolder.createSubfolder(named: "TestApp.xcodeproj")
//        
//        let result = try sut.detectProject(at: tempFolder.path)
//        
//        #expect(result.type.path.contains("TestApp.xcodeproj"))
//        #expect(result.name == "TestApp")
//        #expect(result.supportedPlatforms == [.macOS, .iOS])
//    }
//    
//    @Test("Throws error when no Xcode project exists")
//    func throwsErrorWhenNoXcodeProjectExists() throws {
//        let sut = makeSUT()
//        let tempFolderPath = tempFolder.path
//        
//        // Create some non-Xcode files
//        try tempFolder.createFile(named: "README.md")
//        try tempFolder.createFile(named: "Package.swift")
//        
//        #expect(throws: ArchiveError.self) {
//            try sut.detectProject(at: tempFolderPath)
//        }
//    }
//    
//    @Test("Detects schemes successfully from xcodebuild output")
//    func detectsSchemesSuccessfullyFromXcodebuildOutput() throws {
//        let sut = makeSUT(
//            shellOutputs: [xcodebuildListOutput]
//        )
//        
//        try tempFolder.createSubfolder(named: "TestApp.xcodeproj")
//        let projectInfo = try sut.detectProject(at: tempFolder.path)
//        
//        let schemes = try sut.detectSchemes(for: projectInfo)
//        
//        #expect(schemes == testSchemes)
//    }
//    
//    @Test("Throws error when no schemes found in xcodebuild output")
//    func throwsErrorWhenNoSchemesFound() throws {
//        let emptyOutput = """
//        Information about project "TestApp":
//            Targets:
//                TestApp
//            
//            Build Configurations:
//                Debug
//                Release
//        """
//        
//        let sut = makeSUT(
//            shellOutputs: [emptyOutput]
//        )
//        
//        try tempFolder.createSubfolder(named: "TestApp.xcodeproj")
//        let projectInfo = try sut.detectProject(at: tempFolder.path)
//        
//        #expect(throws: ArchiveError.self) {
//            try sut.detectSchemes(for: projectInfo)
//        }
//    }
//    
//    @Test("Parses schemes correctly from complex xcodebuild output")
//    func parsesSchemesCorrectlyFromComplexOutput() throws {
//        let complexOutput = """
//        Information about project "ComplexApp":
//            Targets:
//                ComplexApp
//                ComplexAppTests
//                ComplexApp-macOS
//                ComplexApp-iOS
//        
//            Build Configurations:
//                Debug
//                Release
//                Staging
//        
//            If no build configuration is specified and -scheme is not passed then "Release" is used.
//        
//            Schemes:
//                ComplexApp
//                ComplexApp-Debug
//                ComplexApp-Release
//                ComplexApp-macOS
//                ComplexApp-iOS
//                ComplexApp Tests
//        """
//        
//        let sut = makeSUT(
//            shellOutputs: [complexOutput]
//        )
//        
//        try tempFolder.createSubfolder(named: "ComplexApp.xcodeproj")
//        let projectInfo = try sut.detectProject(at: tempFolder.path)
//        
//        let schemes = try sut.detectSchemes(for: projectInfo)
//        
//        #expect(schemes.contains("ComplexApp"))
//        #expect(schemes.contains("ComplexApp-Debug"))
//        #expect(schemes.contains("ComplexApp Tests"))
//        #expect(schemes.count == 6)
//    }
//    
//    @Test("Validates platform support successfully for supported platform")
//    func validatesPlatformSupportSuccessfullyForSupportedPlatform() throws {
//        let sut = makeSUT()
//        
//        try tempFolder.createSubfolder(named: "TestApp.xcodeproj")
//        let projectInfo = try sut.detectProject(at: tempFolder.path)
//        
//        // Should not throw for supported platforms
//        try sut.validatePlatformSupport(.macOS, project: projectInfo)
//        try sut.validatePlatformSupport(.iOS, project: projectInfo)
//    }
//    
//    @Test("Throws error when validating unsupported platform")
//    func throwsErrorWhenValidatingUnsupportedPlatform() throws {
//        let sut = makeSUT()
//        
//        try tempFolder.createSubfolder(named: "TestApp.xcodeproj")
//        var projectInfo = try sut.detectProject(at: tempFolder.path)
//        
//        projectInfo = ProjectInfo(
//            path: projectInfo.path,
//            type: projectInfo.type,
//            name: projectInfo.name,
//            supportedPlatforms: [.macOS] // Only macOS supported
//        )
//        
//        #expect(throws: ArchiveError.self) {
//            try sut.validatePlatformSupport(.iOS, project: projectInfo)
//        }
//    }
//    
//    @Test("Extracts correct project name from xcodeproj path")
//    func extractsCorrectProjectNameFromXcodeprojPath() throws {
//        let sut = makeSUT()
//        
//        try tempFolder.createSubfolder(named: "MyAwesomeApp.xcodeproj")
//        
//        let result = try sut.detectProject(at: tempFolder.path)
//        
//        #expect(result.name == "MyAwesomeApp")
//    }
//    
//    @Test("Extracts correct project name from xcworkspace path")
//    func extractsCorrectProjectNameFromXcworkspacePath() throws {
//        let sut = makeSUT()
//        
//        try tempFolder.createFile(named: "SuperCoolWorkspace.xcworkspace")
//        
//        let result = try sut.detectProject(at: tempFolder.path)
//        
//        #expect(result.name == "SuperCoolWorkspace")
//    }
//    
//    @Test("Handles empty schemes section in xcodebuild output")
//    func handlesEmptySchemesSectionInXcodebuildOutput() throws {
//        let outputWithEmptySchemes = """
//        Information about project "TestApp":
//            Targets:
//                TestApp
//            
//            Schemes:
//        """
//        
//        let sut = makeSUT(shellOutputs: [outputWithEmptySchemes])
//        
//        try tempFolder.createSubfolder(named: "TestApp.xcodeproj")
//        let projectInfo = try sut.detectProject(at: tempFolder.path)
//        
//        #expect(throws: ArchiveError.self) {
//            try sut.detectSchemes(for: projectInfo)
//        }
//    }
//    
//    @Test("Handles xcodebuild command failure")
//    func handlesXcodebuildCommandFailure() throws {
//        let sut = makeSUT(shouldThrowShellError: true)
//        try tempFolder.createSubfolder(named: "TestApp.xcodeproj")
//        let projectInfo = try sut.detectProject(at: tempFolder.path)
//        
//        #expect(throws: (any Error).self) {
//            try sut.detectSchemes(for: projectInfo)
//        }
//    }
//}
//
//
//// MARK: - SUT
//private extension ProjectDetectorTests {
//    func makeSUT(shellOutputs: [String] = [], shouldThrowShellError: Bool = false) -> DefaultProjectDetector {
//        let shell = MockShell(results: shellOutputs, shouldThrowErrorOnFinal: shouldThrowShellError)
//        
//        return .init(shell: shell)
//    }
//}
//
//
//// MARK: - Error Validation Extensions
//extension ProjectDetectorTests {
//    @Test("ArchiveError provides correct error descriptions")
//    func archiveErrorProvidesCorrectErrorDescriptions() {
//        let noProjectError = ArchiveError.noXcodeProject(path: "/some/path")
//        let noSchemesError = ArchiveError.noSchemesFound(projectName: "TestProject")
//        let platformError = ArchiveError.platformNotSupported(
//            platform: .iOS,
//            projectName: "TestProject",
//            supportedPlatforms: [.macOS]
//        )
//        let archiveFailedError = ArchiveError.archiveFailed(reason: "Build failed")
//        
//        #expect(noProjectError.errorDescription?.contains("/some/path") == true)
//        #expect(noSchemesError.errorDescription?.contains("TestProject") == true)
//        #expect(platformError.errorDescription?.contains("iOS") == true)
//        #expect(platformError.errorDescription?.contains("macOS") == true)
//        #expect(archiveFailedError.errorDescription?.contains("Build failed") == true)
//    }
//}
