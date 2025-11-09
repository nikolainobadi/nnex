//
//  FormulaContentGeneratorTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/25/25.
//

import Testing
@testable import NnexKit

struct FormulaContentGeneratorTests {
    private let testName = "testtool"
    private let testDetails = "A test command line tool"
    private let testHomepage = "https://github.com/test/testtool"
    private let testLicense = "MIT"
    private let testVersion = "1.0.0"
    private let testAssetURL = "https://github.com/test/testtool/releases/download/v1.0.0/testtool.tar.gz"
    private let testSHA256 = "abc123def456789"
    private let testArmURL = "https://github.com/test/testtool/releases/download/v1.0.0/testtool-arm64.tar.gz"
    private let testArmSHA256 = "arm64sha256hash"
    private let testIntelURL = "https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz"
    private let testIntelSHA256 = "x86_64sha256hash"

    private var expectedName: String {
        return FormulaNameSanitizer.sanitizeFormulaName(testName)
    }
}


// MARK: - Single Binary Tests
extension FormulaContentGeneratorTests {
    @Test("Generates correct formula content for single binary")
    func generatesSingleBinaryFormula() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            assetURL: testAssetURL,
            sha256: testSHA256
        )

        #expect(content.contains("class \(expectedName) < Formula"))
        #expect(content.contains("desc \"A test command line tool\""))
        #expect(content.contains("homepage \"https://github.com/test/testtool\""))
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool.tar.gz\""))
        #expect(content.contains("sha256 \"abc123def456789\""))
        #expect(content.contains("version \"1.0.0\""))
        #expect(content.contains("license \"MIT\""))
        #expect(content.contains("bin.install \"testtool\""))
        #expect(content.contains("system \"#{bin}/testtool\", \"--help\""))
    }
    
    @Test("Capitalizes formula class name correctly")
    func capitalizesFormulaClassName() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: "my-tool",
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            assetURL: testAssetURL,
            sha256: testSHA256
        )

        #expect(content.contains("class MyTool < Formula"))
    }

    @Test("Handles empty strings in single binary formula")
    func handlesEmptyStringsInSingleBinary() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: "",
            homepage: "",
            license: "",
            version: testVersion,
            assetURL: "",
            sha256: ""
        )

        #expect(content.contains("desc \"\""))
        #expect(content.contains("homepage \"\""))
        #expect(content.contains("version \"1.0.0\""))
        #expect(content.contains("license \"\""))
        #expect(content.contains("url \"\""))
        #expect(content.contains("sha256 \"\""))
    }
}


// MARK: - Multiple Binary Tests
extension FormulaContentGeneratorTests {
    @Test("Generates correct formula content for both ARM and Intel binaries")
    func generatesBothArchitecturesFormula() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            armURL: testArmURL,
            armSHA256: testArmSHA256,
            intelURL: testIntelURL,
            intelSHA256: testIntelSHA256
        )

        #expect(content.contains("class \(expectedName) < Formula"))
        #expect(content.contains("desc \"A test command line tool\""))
        #expect(content.contains("homepage \"https://github.com/test/testtool\""))
        #expect(content.contains("version \"1.0.0\""))
        #expect(content.contains("license \"MIT\""))

        // Check ARM section
        #expect(content.contains("on_arm do"))
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-arm64.tar.gz\""))
        #expect(content.contains("sha256 \"arm64sha256hash\""))

        // Check Intel section
        #expect(content.contains("on_intel do"))
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz\""))
        #expect(content.contains("sha256 \"x86_64sha256hash\""))

        // Check install and test sections
        #expect(content.contains("bin.install \"testtool\""))
        #expect(content.contains("system \"#{bin}/testtool\", \"--help\""))

        // Check structure
        #expect(content.contains("on_macos do"))
    }
    
    @Test("Falls back to single binary formula when only ARM is provided")
    func fallsBackToSingleBinaryForArmOnly() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            armURL: testArmURL,
            armSHA256: testArmSHA256,
            intelURL: nil,
            intelSHA256: nil
        )

        // Should generate single binary formula with ARM URL
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-arm64.tar.gz\""))
        #expect(content.contains("sha256 \"arm64sha256hash\""))
        #expect(!content.contains("on_arm do"))
        #expect(!content.contains("on_intel do"))
        #expect(!content.contains("on_macos do"))
    }

    @Test("Falls back to single binary formula when only Intel is provided")
    func fallsBackToSingleBinaryForIntelOnly() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            armURL: nil,
            armSHA256: nil,
            intelURL: testIntelURL,
            intelSHA256: testIntelSHA256
        )

        // Should generate single binary formula with Intel URL
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz\""))
        #expect(content.contains("sha256 \"x86_64sha256hash\""))
        #expect(!content.contains("on_arm do"))
        #expect(!content.contains("on_intel do"))
        #expect(!content.contains("on_macos do"))
    }

    @Test("Handles missing ARM SHA256 with valid URL")
    func handlesMissingArmSHA256() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            armURL: testArmURL,
            armSHA256: nil,
            intelURL: testIntelURL,
            intelSHA256: testIntelSHA256
        )

        // Should only use Intel since ARM is incomplete
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz\""))
        #expect(content.contains("sha256 \"x86_64sha256hash\""))
        #expect(!content.contains(testArmURL))
    }

    @Test("Handles missing Intel URL with valid SHA256")
    func handlesMissingIntelURL() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            armURL: testArmURL,
            armSHA256: testArmSHA256,
            intelURL: nil,
            intelSHA256: testIntelSHA256
        )

        // Should only use ARM since Intel is incomplete
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-arm64.tar.gz\""))
        #expect(content.contains("sha256 \"arm64sha256hash\""))
        #expect(!content.contains("x86_64sha256hash"))
    }

    @Test("Handles empty string URLs as missing")
    func handlesEmptyStringURLsAsMissing() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            armURL: "",
            armSHA256: testArmSHA256,
            intelURL: testIntelURL,
            intelSHA256: testIntelSHA256
        )

        // Empty string should be treated as missing
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz\""))
        #expect(content.contains("sha256 \"x86_64sha256hash\""))
        #expect(!content.contains("on_arm do"))
    }

    @Test("Handles empty string SHA256 as missing")
    func handlesEmptyStringSHA256AsMissing() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            armURL: testArmURL,
            armSHA256: "",
            intelURL: testIntelURL,
            intelSHA256: testIntelSHA256
        )

        // Empty string should be treated as missing
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz\""))
        #expect(content.contains("sha256 \"x86_64sha256hash\""))
        #expect(!content.contains("on_arm do"))
    }

    @Test("Returns empty formula when no valid binaries provided")
    func returnsEmptyFormulaWhenNoBinaries() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            armURL: nil,
            armSHA256: nil,
            intelURL: nil,
            intelSHA256: nil
        )

        // Should generate formula with empty URL and SHA256
        #expect(content.contains("url \"\""))
        #expect(content.contains("sha256 \"\""))
        #expect(content.contains("class \(expectedName) < Formula"))
        #expect(content.contains("desc \"A test command line tool\""))
    }

    @Test("Returns empty formula when all binaries are empty strings")
    func returnsEmptyFormulaWhenAllEmpty() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            armURL: "",
            armSHA256: "",
            intelURL: "",
            intelSHA256: ""
        )

        // Should generate formula with empty URL and SHA256
        #expect(content.contains("url \"\""))
        #expect(content.contains("sha256 \"\""))
        #expect(!content.contains("on_arm do"))
        #expect(!content.contains("on_intel do"))
    }
}


// MARK: - Formula Structure Tests
extension FormulaContentGeneratorTests {
    @Test("Multi-arch formula has correct indentation structure")
    func multiArchFormulaHasCorrectIndentation() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            armURL: testArmURL,
            armSHA256: testArmSHA256,
            intelURL: testIntelURL,
            intelSHA256: testIntelSHA256
        )

        let lines = content.components(separatedBy: "\n")

        // Check that class declaration is not indented
        let classLine = lines.first { $0.contains("class") }
        #expect(classLine?.starts(with: "class") == true)

        // Check that on_macos is indented once (4 spaces)
        let onMacosLine = lines.first { $0.contains("on_macos do") }
        #expect(onMacosLine?.starts(with: "    on_macos") == true)

        // Check that on_arm is indented twice (8 spaces)
        let onArmLine = lines.first { $0.contains("on_arm do") }
        #expect(onArmLine?.starts(with: "        on_arm") == true)

        // Check that URL under on_arm is indented three times (12 spaces)
        if let armIndex = lines.firstIndex(where: { $0.contains("on_arm do") }) {
            let nextLine = lines[armIndex + 1]
            #expect(nextLine.starts(with: "            url"))
        }
    }

    @Test("Single binary formula has correct indentation")
    func singleBinaryFormulaHasCorrectIndentation() {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: testName,
            details: testDetails,
            homepage: testHomepage,
            license: testLicense,
            version: testVersion,
            assetURL: testAssetURL,
            sha256: testSHA256
        )

        let lines = content.components(separatedBy: "\n")

        // Check that class declaration is not indented
        let classLine = lines.first { $0.contains("class") }
        #expect(classLine?.starts(with: "class") == true)

        // Check that desc, homepage, url, etc. are indented once (4 spaces)
        let descLine = lines.first { $0.contains("desc") }
        #expect(descLine?.starts(with: "    desc") == true)

        let urlLine = lines.first { $0.contains("url") }
        #expect(urlLine?.starts(with: "    url") == true)
    }
}
