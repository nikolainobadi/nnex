//
//  HomebrewFormulaDecoderTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/30/25.
//

import Testing
import NnShellTesting
import NnexSharedTestHelpers
@testable import NnexKit

struct HomebrewFormulaDecoderTests {
    @Test("Returns warning when Formula folder is missing")
    func missingFormulaFolder() throws {
        let tapFolder = MockDirectory(path: "/taps/homebrew-myTap")
        let (decoder, _) = makeSUT()
        
        let (formulas, warnings) = try decoder.decodeFormulas(in: tapFolder)
        
        #expect(formulas.isEmpty)
        #expect(warnings.count == 1)
        #expect(warnings.first?.contains("No 'Formula' folder") == true)
    }
    
    @Test("Decodes formulas using brew JSON output")
    func decodeUsingBrewOutput() throws {
        let fileName = "mytool.rb"
        let (tapFolder, _) = makeTapFolder(containedFiles: [fileName])
        let (decoder, shell) = makeSUT(shellResults: [
            "/opt/homebrew/bin/brew", // which brew
            """
            {"formulae":[{"name":"mytool","desc":"A useful tool","homepage":"https://example.com","license":"MIT","versions":{"stable":"https://example.com/mytool.tar.gz"}}]}
            """
        ])
        
        let (formulas, warnings) = try decoder.decodeFormulas(in: tapFolder)
        let formula = try #require(formulas.first)
        
        #expect(formulas.count == 1)
        #expect(warnings.isEmpty)
        #expect(formula.name == "mytool")
        #expect(formula.details == "A useful tool")
        #expect(formula.homepage == "https://example.com")
        #expect(formula.license == "MIT")
        #expect(formula.uploadType == .tarball)
        #expect(shell.executedCommands.count == 2)
        #expect(shell.executedCommands[1].contains("brew info --json=v2"))
        #expect(shell.executedCommands[1].contains(fileName))
    }
    
    @Test("Falls back to parsing file contents when brew is unavailable")
    func fallbackDecodingWhenBrewUnavailable() throws {
        let fileName = "mytool.rb"
        let (tapFolder, formulaFolder) = makeTapFolder(containedFiles: [fileName])
        formulaFolder.fileContents[fileName] = """
        class MyTool < Formula
        desc "A fallback tool"
        homepage "https://example.com/fallback"
        license "Apache-2.0"
        end
        """
        let (decoder, shell) = makeSUT(shellResults: ["not found"]) // which brew
        
        let (formulas, warnings) = try decoder.decodeFormulas(in: tapFolder)
        let formula = try #require(formulas.first)
        
        #expect(formulas.count == 1)
        #expect(warnings.count == 1)
        #expect(formula.name == "MyTool")
        #expect(formula.details == "A fallback tool")
        #expect(formula.homepage == "https://example.com/fallback")
        #expect(formula.license == "Apache-2.0")
        #expect(formula.uploadType == .binary)
        #expect(shell.executedCommands.count == 1)
    }
}


// MARK: - SUT
private extension HomebrewFormulaDecoderTests {
    func makeSUT(shellResults: [String] = []) -> (sut: HomebrewFormulaDecoder, shell: MockShell) {
        let shell = MockShell(results: shellResults)
        let sut = HomebrewFormulaDecoder(shell: shell)
        
        return (sut, shell)
    }
}


// MARK: - Test Helpers
private extension HomebrewFormulaDecoderTests {
    func makeTapFolder(containedFiles: Set<String>) -> (tap: MockDirectory, formula: MockDirectory) {
        let formulaFolder = MockDirectory(path: "/taps/homebrew-myTap/Formula", containedFiles: containedFiles)
        let tapFolder = MockDirectory(path: "/taps/homebrew-myTap", subdirectories: [formulaFolder])
        return (tapFolder, formulaFolder)
    }
}
