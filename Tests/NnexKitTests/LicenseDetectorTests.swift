//
//  LicenseDetectorTests.swift
//  NnexKitTests
//
//  Created by Nikolai Nobadi on 12/9/25.
//

import Testing
import Foundation
import NnexSharedTestHelpers
@testable import NnexKit

struct LicenseDetectorTests {
    private let projectPath = "/test/project"
}


// MARK: - Tests
extension LicenseDetectorTests {
    @Test("Detects MIT license from LICENSE file")
    func detectsMITLicense() throws {
        let directory = makeDirectory(fileName: "LICENSE", content: "MIT License\n\nCopyright (c) 2025")

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "MIT")
    }

    @Test("Detects Apache license from LICENSE file")
    func detectsApacheLicense() throws {
        let directory = makeDirectory(fileName: "LICENSE", content: "Apache License\nVersion 2.0")

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "Apache")
    }

    @Test("Detects GPL license from LICENSE file")
    func detectsGPLLicense() throws {
        let directory = makeDirectory(fileName: "LICENSE", content: "GNU General Public License\nVersion 3")

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "GPL")
    }

    @Test("Detects BSD license from LICENSE file")
    func detectsBSDLicense() throws {
        let directory = makeDirectory(fileName: "LICENSE", content: "BSD License\n\nRedistribution and use...")

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "BSD")
    }

    @Test("Returns empty string when no license file exists")
    func returnsEmptyWhenNoLicenseFile() throws {
        let directory = MockDirectory(path: projectPath, containedFiles: [])

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "")
    }

    @Test("Returns empty string when license file exists but type is unknown")
    func returnsEmptyForUnknownLicense() throws {
        let directory = makeDirectory(fileName: "LICENSE", content: "Custom License Agreement")

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "")
    }

    @Test("Detects license from LICENSE.md file")
    func detectsLicenseFromMarkdownFile() throws {
        let directory = makeDirectory(fileName: "LICENSE.md", content: "# License\n\nMIT License")

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "MIT")
    }

    @Test("Detects license from COPYING file")
    func detectsLicenseFromCopyingFile() throws {
        let directory = makeDirectory(fileName: "COPYING", content: "GNU General Public License")

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "GPL")
    }

    @Test("Returns first detected license when multiple license files exist")
    func returnsFirstLicenseWhenMultipleExist() throws {
        let directory = MockDirectory(path: projectPath, containedFiles: ["LICENSE", "LICENSE.md"])
        directory.fileContents["LICENSE"] = "MIT License"
        directory.fileContents["LICENSE.md"] = "Apache License"

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "MIT")
    }

    @Test("Checks LICENSE file before LICENSE.md")
    func checksLicenseBeforeLicenseMd() throws {
        let directory = MockDirectory(path: projectPath, containedFiles: ["LICENSE.md"])
        directory.fileContents["LICENSE.md"] = "BSD License"

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "BSD")
    }

    @Test("Returns empty string when license file is empty")
    func returnsEmptyForEmptyLicenseFile() throws {
        let directory = makeDirectory(fileName: "LICENSE", content: "")

        let result = LicenseDetector.detectLicense(in: directory)

        #expect(result == "")
    }
}


// MARK: - Helpers
private extension LicenseDetectorTests {
    func makeDirectory(fileName: String, content: String) -> MockDirectory {
        let directory = MockDirectory(path: projectPath, containedFiles: [fileName])
        directory.fileContents[fileName] = content
        return directory
    }
}
