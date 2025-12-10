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
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let assetURL = testAssetURL
        let sha256 = testSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            assetURL: assetURL,
            sha256: sha256
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
        let sut = makeSUT()
        let name = "my-tool"
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let assetURL = testAssetURL
        let sha256 = testSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            assetURL: assetURL,
            sha256: sha256
        )
        
        #expect(content.contains("class MyTool < Formula"))
    }

    @Test("Handles empty strings in single binary formula")
    func handlesEmptyStringsInSingleBinary() {
        let sut = makeSUT()
        let name = testName
        let details = ""
        let homepage = ""
        let license = ""
        let version = testVersion
        let assetURL = ""
        let sha256 = ""
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            assetURL: assetURL,
            sha256: sha256
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
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let armURL = testArmURL
        let armSHA256 = testArmSHA256
        let intelURL = testIntelURL
        let intelSHA256 = testIntelSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        #expect(content.contains("class \(expectedName) < Formula"))
        #expect(content.contains("desc \"A test command line tool\""))
        #expect(content.contains("homepage \"https://github.com/test/testtool\""))
        #expect(content.contains("version \"1.0.0\""))
        #expect(content.contains("license \"MIT\""))
        #expect(content.contains("on_arm do"))
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-arm64.tar.gz\""))
        #expect(content.contains("sha256 \"arm64sha256hash\""))
        #expect(content.contains("on_intel do"))
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz\""))
        #expect(content.contains("sha256 \"x86_64sha256hash\""))
        #expect(content.contains("bin.install \"testtool\""))
        #expect(content.contains("system \"#{bin}/testtool\", \"--help\""))
        #expect(content.contains("on_macos do"))
    }
    
    @Test("Falls back to single binary formula when only ARM is provided")
    func fallsBackToSingleBinaryForArmOnly() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let armURL = testArmURL
        let armSHA256 = testArmSHA256
        let intelURL: String? = nil
        let intelSHA256: String? = nil
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-arm64.tar.gz\""))
        #expect(content.contains("sha256 \"arm64sha256hash\""))
        #expect(!content.contains("on_arm do"))
        #expect(!content.contains("on_intel do"))
        #expect(!content.contains("on_macos do"))
    }

    @Test("Falls back to single binary formula when only Intel is provided")
    func fallsBackToSingleBinaryForIntelOnly() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let armURL: String? = nil
        let armSHA256: String? = nil
        let intelURL = testIntelURL
        let intelSHA256 = testIntelSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz\""))
        #expect(content.contains("sha256 \"x86_64sha256hash\""))
        #expect(!content.contains("on_arm do"))
        #expect(!content.contains("on_intel do"))
        #expect(!content.contains("on_macos do"))
    }

    @Test("Handles missing ARM SHA256 with valid URL")
    func handlesMissingArmSHA256() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let armURL = testArmURL
        let armSHA256: String? = nil
        let intelURL = testIntelURL
        let intelSHA256 = testIntelSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz\""))
        #expect(content.contains("sha256 \"x86_64sha256hash\""))
        #expect(!content.contains(testArmURL))
    }

    @Test("Handles missing Intel URL with valid SHA256")
    func handlesMissingIntelURL() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let armURL = testArmURL
        let armSHA256 = testArmSHA256
        let intelURL: String? = nil
        let intelSHA256 = testIntelSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-arm64.tar.gz\""))
        #expect(content.contains("sha256 \"arm64sha256hash\""))
        #expect(!content.contains("x86_64sha256hash"))
    }

    @Test("Handles empty string URLs as missing")
    func handlesEmptyStringURLsAsMissing() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let armURL = ""
        let armSHA256 = testArmSHA256
        let intelURL = testIntelURL
        let intelSHA256 = testIntelSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz\""))
        #expect(content.contains("sha256 \"x86_64sha256hash\""))
        #expect(!content.contains("on_arm do"))
    }

    @Test("Handles empty string SHA256 as missing")
    func handlesEmptyStringSHA256AsMissing() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let armURL = testArmURL
        let armSHA256 = ""
        let intelURL = testIntelURL
        let intelSHA256 = testIntelSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        #expect(content.contains("url \"https://github.com/test/testtool/releases/download/v1.0.0/testtool-x86_64.tar.gz\""))
        #expect(content.contains("sha256 \"x86_64sha256hash\""))
        #expect(!content.contains("on_arm do"))
    }

    @Test("Returns empty formula when no valid binaries provided")
    func returnsEmptyFormulaWhenNoBinaries() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let armURL: String? = nil
        let armSHA256: String? = nil
        let intelURL: String? = nil
        let intelSHA256: String? = nil
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        #expect(content.contains("url \"\""))
        #expect(content.contains("sha256 \"\""))
        #expect(content.contains("class \(expectedName) < Formula"))
        #expect(content.contains("desc \"A test command line tool\""))
    }

    @Test("Returns empty formula when all binaries are empty strings")
    func returnsEmptyFormulaWhenAllEmpty() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let armURL = ""
        let armSHA256 = ""
        let intelURL = ""
        let intelSHA256 = ""
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
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
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let armURL = testArmURL
        let armSHA256 = testArmSHA256
        let intelURL = testIntelURL
        let intelSHA256 = testIntelSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        let lines = content.components(separatedBy: "\n")
        
        let classLine = lines.first { $0.contains("class") }
        #expect(classLine?.starts(with: "class") == true)
        
        let onMacosLine = lines.first { $0.contains("on_macos do") }
        #expect(onMacosLine?.starts(with: "    on_macos") == true)
        
        let onArmLine = lines.first { $0.contains("on_arm do") }
        #expect(onArmLine?.starts(with: "        on_arm") == true)
        
        if let armIndex = lines.firstIndex(where: { $0.contains("on_arm do") }) {
            let nextLine = lines[armIndex + 1]
            #expect(nextLine.starts(with: "            url"))
        }
    }

    @Test("Single binary formula has correct indentation")
    func singleBinaryFormulaHasCorrectIndentation() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = testVersion
        let assetURL = testAssetURL
        let sha256 = testSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            assetURL: assetURL,
            sha256: sha256
        )
        
        let lines = content.components(separatedBy: "\n")
        
        let classLine = lines.first { $0.contains("class") }
        #expect(classLine?.starts(with: "class") == true)
        
        let descLine = lines.first { $0.contains("desc") }
        #expect(descLine?.starts(with: "    desc") == true)
        
        let urlLine = lines.first { $0.contains("url") }
        #expect(urlLine?.starts(with: "    url") == true)
    }
}


// MARK: - Version Sanitization Tests
extension FormulaContentGeneratorTests {
    @Test("Strips v prefix from version in single binary formula")
    func stripsVPrefixFromVersionInSingleBinary() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = "v1.0.0"
        let assetURL = testAssetURL
        let sha256 = testSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            assetURL: assetURL,
            sha256: sha256
        )
        
        #expect(content.contains("version \"1.0.0\""))
        #expect(!content.contains("version \"v1.0.0\""))
    }

    @Test("Strips v prefix from version in multi-arch formula")
    func stripsVPrefixFromVersionInMultiArch() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = "v2.5.3"
        let armURL = testArmURL
        let armSHA256 = testArmSHA256
        let intelURL = testIntelURL
        let intelSHA256 = testIntelSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        #expect(content.contains("version \"2.5.3\""))
        #expect(!content.contains("version \"v2.5.3\""))
    }

    @Test("Preserves version without v prefix in single binary formula")
    func preservesVersionWithoutVPrefixInSingleBinary() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = "3.0.0"
        let assetURL = testAssetURL
        let sha256 = testSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            assetURL: assetURL,
            sha256: sha256
        )
        
        #expect(content.contains("version \"3.0.0\""))
    }

    @Test("Preserves version without v prefix in multi-arch formula")
    func preservesVersionWithoutVPrefixInMultiArch() {
        let sut = makeSUT()
        let name = testName
        let details = testDetails
        let homepage = testHomepage
        let license = testLicense
        let version = "4.2.1"
        let armURL = testArmURL
        let armSHA256 = testArmSHA256
        let intelURL = testIntelURL
        let intelSHA256 = testIntelSHA256
        let content = sut.makeFormulaFileContent(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: armURL,
            armSHA256: armSHA256,
            intelURL: intelURL,
            intelSHA256: intelSHA256
        )
        
        #expect(content.contains("version \"4.2.1\""))
    }
}


// MARK: - SUT
private extension FormulaContentGeneratorTests {
    func makeSUT() -> FormulaContentGenerator.Type {
        return FormulaContentGenerator.self
    }
}
