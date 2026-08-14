import Testing

@testable import GitHub_Traffic

extension GitHub.Repository.Traffic {
    @Suite("GitHub.Repository.Traffic.Client.Unit")
    struct Core {
        @Test("Each traffic endpoint is a typed one-call capability")
        func capabilities() async throws(GitHub.Repository.Traffic.Fixture.Failure) {
            let client = Client<GitHub.Repository.Traffic.Fixture.Failure>(
                views: { _ async throws(GitHub.Repository.Traffic.Fixture.Failure) in
                    .init(count: 1, uniques: 1, views: [])
                },
                clones: { _ async throws(GitHub.Repository.Traffic.Fixture.Failure) in
                    .init(count: 2, uniques: 2, clones: [])
                },
                paths: { _ async throws(GitHub.Repository.Traffic.Fixture.Failure) in
                    .init(paths: [])
                },
                referrers: { _ async throws(GitHub.Repository.Traffic.Fixture.Failure) in
                    .init(referrers: [])
                }
            )
            let owner = GitHub.Owner.Login("swiftlang")
            let repository = GitHub.Repository.Name("swift")

            let views = try await client.views(
                .init(owner: owner, repository: repository, interval: .day)
            )
            let clones = try await client.clones(
                .init(owner: owner, repository: repository, interval: .week)
            )
            let paths = try await client.paths(
                .init(owner: owner, repository: repository)
            )
            let referrers = try await client.referrers(
                .init(owner: owner, repository: repository)
            )

            #expect(views.count == 1)
            #expect(clones.count == 2)
            #expect(paths.paths.isEmpty)
            #expect(referrers.referrers.isEmpty)
        }

        @Test("Traffic endpoint failures remain typed")
        func failure() async {
            let client = Client<GitHub.Repository.Traffic.Fixture.Failure>(
                views: {
                    (
                        _: Views.Request
                    ) async throws(GitHub.Repository.Traffic.Fixture.Failure)
                        -> Views.Response in
                    throw .expected
                },
                clones: {
                    (
                        _: Clones.Request
                    ) async throws(GitHub.Repository.Traffic.Fixture.Failure)
                        -> Clones.Response in
                    throw .expected
                },
                paths: {
                    (
                        _: Paths.Request
                    ) async throws(GitHub.Repository.Traffic.Fixture.Failure)
                        -> Paths.Response in
                    throw .expected
                },
                referrers: {
                    (
                        _: Referrers.Request
                    ) async throws(GitHub.Repository.Traffic.Fixture.Failure)
                        -> Referrers.Response in
                    throw .expected
                }
            )
            let owner = GitHub.Owner.Login("swiftlang")
            let repository = GitHub.Repository.Name("swift")

            let views = Views.Request(owner: owner, repository: repository)
            let clones = Clones.Request(owner: owner, repository: repository)
            let paths = Paths.Request(owner: owner, repository: repository)
            let referrers = Referrers.Request(owner: owner, repository: repository)
            await #expect(throws: GitHub.Repository.Traffic.Fixture.Failure.expected) {
                try await client.views(views)
            }
            await #expect(throws: GitHub.Repository.Traffic.Fixture.Failure.expected) {
                try await client.clones(clones)
            }
            await #expect(throws: GitHub.Repository.Traffic.Fixture.Failure.expected) {
                try await client.paths(paths)
            }
            await #expect(throws: GitHub.Repository.Traffic.Fixture.Failure.expected) {
                try await client.referrers(referrers)
            }
        }
    }
}
