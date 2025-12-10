//
//  FormulaNameSanitizerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Testing
@testable import NnexKit

struct FormulaNameSanitizerTests {
    @Test("Converts simple dash-separated name to PascalCase")
    func convertsSimpleDashName() {
        let input = "my-tool"
        let expected = "MyTool"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
    
    @Test("Converts multiple-dash name to PascalCase")
    func convertsMultipleDashName() {
        let input = "awesome-cli-tool"
        let expected = "AwesomeCliTool"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
    
    @Test("Handles name without dashes")
    func handlesNameWithoutDashes() {
        let input = "tool"
        let expected = "Tool"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
    
    @Test("Handles consecutive dashes")
    func handlesConsecutiveDashes() {
        let input = "my--awesome---tool"
        let expected = "MyAwesomeTool"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
    
    @Test("Handles leading dash")
    func handlesLeadingDash() {
        let input = "-my-tool"
        let expected = "MyTool"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
    
    @Test("Handles trailing dash")
    func handlesTrailingDash() {
        let input = "my-tool-"
        let expected = "MyTool"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
    
    @Test("Handles only dashes")
    func handlesOnlyDashes() {
        let input = "---"
        let expected = "---"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
    
    @Test("Preserves case of already capitalized components")
    func preservesCapitalizedComponents() {
        let input = "My-Awesome-Tool"
        let expected = "MyAwesomeTool"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
    
    @Test("Handles lowercase components")
    func handlesLowercaseComponents() {
        let input = "swift-package-manager"
        let expected = "SwiftPackageManager"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
    
    @Test("Real-world example: nnex")
    func handlesNnex() {
        let input = "nnex"
        let expected = "Nnex"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
    
    @Test("Real-world example: code-tap")
    func handlesCodeTap() {
        let input = "code-tap"
        let expected = "CodeTap"
        let result = makeSUT().sanitizeFormulaName(input)
        
        #expect(result == expected)
    }
}


// MARK: - SUT
private extension FormulaNameSanitizerTests {
    func makeSUT() -> FormulaNameSanitizer.Type {
        return FormulaNameSanitizer.self
    }
}
