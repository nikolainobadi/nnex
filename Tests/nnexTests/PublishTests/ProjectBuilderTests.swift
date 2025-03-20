//
//  ProjectBuilderTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Testing
@testable import nnex

struct ProjectBuilderTests {
    @Test("Successfully builds a universal binary")
    func buildUniversalBinary() throws {
        let sha256 = "abc123def456"
        let sut = makeSUT(runResults: [sha256]).sut
        let projectName = "TestProject"
        let projectPath = "/path/to/project"
        let result = try sut.buildProject(name: projectName, path: projectPath)
        
        #expect(result.path.contains(projectPath))
        #expect(result.path.contains(projectName))
        #expect(result.sha256 == sha256, "Expected SHA-256 \(sha256), but got \(result.sha256)")
    }
    
    @Test("Throws error if build for architecture fails")
    func buildArchitectureFails() throws {
        let (sut, _) = makeSUT(throwShellError: true)
        
        #expect(throws: (any Error).self) {
            try sut.buildProject(name: "TestProject", path: "/path/to/project")
        }
    }
    
    @Test("Throws error if universal binary creation fails")
    func buildUniversalBinaryFails() throws {
        let (sut, _) = makeSUT(runResults: ["some/path"], throwShellError: true)
        
        #expect(throws: (any Error).self) {
            try sut.buildProject(name: "TestProject", path: "/path/to/project")
        }
    }
    
    @Test("Throws error if SHA-256 calculation fails")
    func sha256CalculationFails() throws {
        let (sut, _) = makeSUT(runResults: ["some/path"], throwShellError: true)
        
        #expect(throws: (any Error).self) {
            try sut.buildProject(name: "TestProject", path: "/path/to/project")
        }
    }
}

// MARK: - SUT
private extension ProjectBuilderTests {
    func makeSUT(runResults: [String] = [], throwShellError: Bool = false) -> (sut: ProjectBuilder, shell: MockShell) {
        let shell = MockShell(runResults: runResults, shouldThrowError: throwShellError)
        let sut = ProjectBuilder(shell: shell)
        return (sut, shell)
    }
}
