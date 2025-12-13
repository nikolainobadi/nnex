////
////  ReleaseNotesHandler.swift
////  nnex
////
////  Created by Nikolai Nobadi on 3/24/25.
////
//
//import NnexKit
//import Foundation
//import GitCommandGen
//
//struct ReleaseNotesHandler {
//    private let picker: any NnexPicker
//    private let projectName: String
//    private let folderBrowser: any DirectoryBrowser
//    private let fileUtility: ReleaseNotesFileUtility
//    
//    init(picker: any NnexPicker, projectName: String, fileUtility: ReleaseNotesFileUtility, folderBrowser: any DirectoryBrowser) {
//        self.picker = picker
//        self.projectName = projectName
//        self.fileUtility = fileUtility
//        self.folderBrowser = folderBrowser
//    }
//}
//
//
//// MARK: - Action
//extension ReleaseNotesHandler {
//    func getReleaseNoteInfo() throws -> ReleaseNoteInfo {
//        switch try picker.requiredSingleSelection("How would you like to add your release notes for \(projectName)?", items: NoteContentType.allCases) {
//        case .direct:
//            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")
//            
//            return .init(content: notes, isFromFile: false)
//        case .selectFile:
//            let filePath = try folderBrowser.browseForFile(prompt: "Select the file containing your release notes.")
//            
//            return .init(content: filePath, isFromFile: true)
//        case .fromPath:
//            let filePath = try picker.getRequiredInput(prompt: "Enter the path to the file for the \(projectName) release notes.")
//            
//            return .init(content: filePath, isFromFile: true)
//        case .createFile:
//            let releaseNotesFile = try fileUtility.createAndOpenNewNoteFile(projectName: projectName)
//            
//            return try fileUtility.validateAndConfirmNoteFile(releaseNotesFile)
//        }
//    }
//}
//
//
//// MARK: - Dependencies
//extension ReleaseNotesHandler {
//    enum NoteContentType: CaseIterable {
//        case direct, selectFile, fromPath, createFile
//    }
//}
