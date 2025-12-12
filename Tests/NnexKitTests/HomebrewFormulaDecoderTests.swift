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
        let decoder = HomebrewFormulaDecoder(shell: MockShell())
        
        let (formulas, warnings) = try decoder.decodeFormulas(in: tapFolder)
        
        #expect(formulas.isEmpty)
        #expect(warnings.count == 1)
        #expect(warnings.first?.contains("No 'Formula' folder") == true)
    }
    
    @Test("Decodes formulas using brew JSON output")
    func decodeUsingBrewOutput() throws {
        let fileName = "mytool.rb"
        let formulaFolder = MockDirectory(path: "/taps/homebrew-myTap/Formula", containedFiles: [fileName])
        let tapFolder = MockDirectory(path: "/taps/homebrew-myTap", subdirectories: [formulaFolder])
        let shell = MockShell(results: [
            "/opt/homebrew/bin/brew", // which brew
            """
            {"formulae":[{"name":"mytool","desc":"A useful tool","homepage":"https://example.com","license":"MIT","versions":{"stable":"https://example.com/mytool.tar.gz"}}]}
            """
        ])
        let decoder = HomebrewFormulaDecoder(shell: shell)
        
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
        let formulaContent = """
        class MyTool < Formula
        desc "A fallback tool"
        homepage "https://example.com/fallback"
        license "Apache-2.0"
        end
        """
        let formulaFolder = MockDirectory(path: "/taps/homebrew-myTap/Formula", containedFiles: [fileName])
        formulaFolder.fileContents[fileName] = formulaContent
        let tapFolder = MockDirectory(path: "/taps/homebrew-myTap", subdirectories: [formulaFolder])
        let shell = MockShell(results: ["not found"]) // which brew
        let decoder = HomebrewFormulaDecoder(shell: shell)
        
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
