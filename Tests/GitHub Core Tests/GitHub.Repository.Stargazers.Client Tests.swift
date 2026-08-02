import Testing

@testable import GitHub

extension GitHub.Repository.Stargazers {
    @Suite("GitHub.Repository.Stargazers.Client.Unit")
    struct Core {
        @Test("Traversal follows stargazer pages")
        func traversal() async throws {
            guard let second = GitHub.Page.Number(rawValue: 2) else {
                Issue.record("invalid page fixture")
                return
            }
            let owner = GitHub.Owner.Login("swiftlang")
            let repository = GitHub.Repository.Name("swift")
            let client = Client {
                (request: Request) async throws(Either<Async.Lifecycle.Error, Page.Error>)
                    -> Page in
                // swift-linter:disable:next raw value access
                // REASON: the fixture pages by the newtype's raw wire number —
                //   the test's purpose is the paging boundary itself.
                switch request.page?.rawValue {
                case 1:
                    return .init(
                        response: .init(stargazers: []),
                        next: .init(
                            owner: owner,
                            repository: repository,
                            page: second,
                            size: .maximum
                        )
                    )

                case 2:
                    return .init(response: .init(stargazers: []), next: nil)

                default:
                    throw .right(.transport)
                }
            }

            let first = Request(
                owner: owner,
                repository: repository,
                page: .first,
                size: .maximum
            )
            let limit: GitHub.Repository.Stargazers.Traversal.Limit
            do throws(GitHub.Repository.Fixture.Failure) {
                limit = try self.limit(pages: 2, items: 1)
            } catch {
                Issue.record("invalid traversal limit fixture: \(error)")
                return
            }
            let stargazers = try await client.all(first, limit: limit)
            #expect(stargazers.isEmpty)
        }

        @Test("Traversal reports typed client, cycle, page, and cancellation failures")
        func failures() async {
            let request = GitHub.Repository.Stargazers.Request(
                owner: .init("swiftlang"),
                repository: .init("swift"),
                page: .first,
                size: .maximum
            )
            let failing = Client {
                (_: Request) async throws(Either<Async.Lifecycle.Error, Page.Error>) -> Page in
                throw .right(.transport)
            }
            await #expect(
                throws:
                    Either<Async.Lifecycle.Error, GitHub.Repository.Stargazers.Traversal.Error>
                        .right(.page(.transport))
            ) {
                try await failing.all(
                    request,
                    limit: try limit(pages: 1, items: 1)
                )
            }

            let cycling = Client {
                (_: Request) async throws(Either<Async.Lifecycle.Error, Page.Error>) -> Page in
                .init(response: .init(stargazers: []), next: request)
            }
            await #expect(
                throws:
                    Either<Async.Lifecycle.Error, GitHub.Repository.Stargazers.Traversal.Error>
                        .right(.cycle)
            ) {
                try await cycling.all(
                    request,
                    limit: try limit(pages: 2, items: 1)
                )
            }
            await #expect(
                throws:
                    Either<Async.Lifecycle.Error, GitHub.Repository.Stargazers.Traversal.Error>
                        .right(.pages)
            ) {
                try await cycling.all(
                    request,
                    limit: try limit(pages: 1, items: 1)
                )
            }

            let task = Task {
                try await cycling.all(
                    request,
                    limit: try limit(pages: 2, items: 1)
                )
            }
            task.cancel()
            await #expect(
                throws:
                    Either<Async.Lifecycle.Error, GitHub.Repository.Stargazers.Traversal.Error>
                        .left(.cancelled)
            ) {
                try await task.value
            }
        }

        private func limit(
            pages: UInt,
            items: UInt
        ) throws(GitHub.Repository.Fixture.Failure)
            -> GitHub.Repository.Stargazers.Traversal.Limit
        {
            guard
                let pages = GitHub.Repository.Stargazers.Traversal.Limit.Pages(
                    rawValue: pages
                ),
                let items = GitHub.Repository.Stargazers.Traversal.Limit.Items(
                    rawValue: items
                )
            else { throw .unexpected }
            return .init(pages: pages, items: items)
        }
    }
}
