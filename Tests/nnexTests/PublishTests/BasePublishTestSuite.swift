////
////  BasePublishTestSuite.swift
////  nnex
////
////  Created by Nikolai Nobadi on 9/10/25.
////
//
//import Foundation
//import NnexSharedTestHelpers
//@testable import nnex
//@preconcurrency import Files
//
//@MainActor
//class BasePublishTestSuite: TempFolderTestSuiteTemplate<TapProjectFolderConfig> {
//    var tapFolder: Folder {
//        return folders.tapFolder
//    }
//    
//    var projectFolder: Folder {
//        return folders.projectFolder
//    }
//    
//    init(tapName: String = "TapName", projectName: String = "PublishTestProject") throws {
//        let tempFolder = try Self.makeTempFolder(name: "PublishTests")
//        let projectFolder = try tempFolder.createSubfolder(named: projectName)
//        let tapFolder = try tempFolder.createSubfolder(named: "homebrew-\(tapName)-\(UUID().uuidString)")
//        super.init(folders: .init(tempFolder: tempFolder, projectFolder: projectFolder, tapFolder: tapFolder))
//    }
//    
//    func createPackageSwift(in folder: Folder? = nil, packageName: String? = nil, executableName: String? = nil) throws {
//        let targetFolder = folder ?? projectFolder
//        let name = packageName ?? targetFolder.name
//        let executable = executableName ?? name
//        
//        let packageContent = """
//        // swift-tools-version: 6.0
//        import PackageDescription
//        
//        let package = Package(
//            name: "\(name)",
//            platforms: [
//                .macOS(.v14)
//            ],
//            products: [
//                .executable(name: "\(executable)", targets: ["\(executable)"])
//            ],
//            targets: [
//                .executableTarget(
//                    name: "\(executable)",
//                    path: "Sources"
//                )
//            ]
//        )
//        """
//        try targetFolder.createFile(named: "Package.swift", contents: packageContent.data(using: .utf8)!)
//    }
//}
//
//
//// MARK: - Dependencies
//struct TapProjectFolderConfig: TestFolderConfiguration {
//    let tempFolder: Folder
//    let projectFolder: Folder
//    let tapFolder: Folder
//}
