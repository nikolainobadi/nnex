//
//  BrewTapListTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Testing
@testable import nnex

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
struct BrewTapListTests {
    @Test("Dispays details for each existing tap")
    func existingTaplist() throws {
        let testFactory = MockContextFactory()
        let context = try testFactory.makeContext()
        let mockTap = makeTap()
        try context.saveNewTap(mockTap)
        
        let output = try getOutput(factory: testFactory)

        for tap in try context.loadTaps() {
            #expect(output.contains(tap.name))
            #expect(output.contains(tap.localPath))
            #expect(output.contains(tap.remotePath))
        }
    }
}


// MARK: - SUT
private extension BrewTapListTests {
    func getOutput(factory: MockContextFactory? = nil) throws -> String {
        return try Nnex.testRun(contextFactory: factory, args: ["brew", "tap-list"])
    }
}


// MARK: - Helpers
private extension BrewTapListTests {
    func makeTap() -> SwiftDataTap {
        return .init(name: "test-tap", localPath: "/usr/local/test", remotePath: "https://github.com/test")
    }
}
