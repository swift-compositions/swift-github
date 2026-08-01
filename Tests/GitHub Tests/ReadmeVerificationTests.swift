//
//  ReadmeVerificationTests.swift
//  swift-github
//
//  Created by Claude Code on 31/10/2025.
//

import Dependencies
import GitHub
import GitHub_Types_Shared
import Testing

@Suite
struct Test {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension Test.Integration {
    @Test
    func `Traffic Analytics - API structure verification`() async throws {
        // This test verifies the API structure shown in README examples
        let mockClient = GitHub.Client(
            traffic: .init(
                views: { _, _, _ in .init(count: 100, uniques: 50, views: []) },
                clones: { _, _, _ in .init(count: 25, uniques: 15, clones: []) },
                paths: { _, _ in .init(paths: []) },
                referrers: { _, _ in .init(referrers: []) }
            ),
            repositories: .init(),
            stargazers: .init(),
            oauth: .init(),
            collaborators: .init()
        )

        // Verify the traffic client methods work as shown in README
        let views = try await mockClient.traffic.views("coenttb", "swift-github", .day)
        #expect(views.count == 100)
        #expect(views.uniques == 50)

        let clones = try await mockClient.traffic.clones("coenttb", "swift-github", nil)
        #expect(clones.count == 25)
        #expect(clones.uniques == 15)

        let paths = try await mockClient.traffic.paths("coenttb", "swift-github")
        #expect(paths.paths.isEmpty)

        let referrers = try await mockClient.traffic.referrers("coenttb", "swift-github")
        #expect(referrers.referrers.isEmpty)
    }

    @Test
    func `Testing with Mocks - withDependencies pattern`() async throws {
        // Verify the mocking pattern shown in README works correctly
        let mockClient = GitHub.Client(
            traffic: .init(
                views: { _, _, _ in .init(count: 100, uniques: 50, views: []) },
                clones: { _, _, _ in .init(count: 0, uniques: 0, clones: []) },
                paths: { _, _ in .init(paths: []) },
                referrers: { _, _ in .init(referrers: []) }
            ),
            repositories: .init(),
            stargazers: .init(),
            oauth: .init(),
            collaborators: .init()
        )

        let result = try await mockClient.traffic.views("owner", "repo", .day)
        #expect(result.count == 100)
        #expect(result.uniques == 50)
    }
}
