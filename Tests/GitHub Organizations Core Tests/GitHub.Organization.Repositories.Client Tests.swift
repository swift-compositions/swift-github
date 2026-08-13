import Testing

@testable import GitHub_Organizations

extension GitHub.Organization.Repositories {
    @Suite("GitHub.Organization.Repositories.Client.Unit")
    struct Core {
        @Test("Traversal follows pages and applies explicit ordering")
        func traversal() async throws {
            let client = try self.client()
            let request = self.request(page: .first)
            let repositories = try await client.all(
                request,
                limit: self.bounds(pages: 2, items: 4),
                duplicate: .preserve,
                order: .init {
                    $0.sorted { $0.name.underlying < $1.name.underlying }
                }
            )

            #expect(
                repositories.map(\.name.underlying)
                    == ["alpha", "alpha-later", "beta", "gamma"]
            )
        }

        @Test("Traversal applies the selected duplicate policy")
        func duplicate() async throws {
            let client = try self.client()
            let request = self.request(page: .first)
            let repositories = try await client.all(
                request,
                limit: self.bounds(pages: 2, items: 3),
                duplicate: .first,
                order: .server
            )

            #expect(repositories.map(\.id.underlying) == [2, 1, 3])
            await #expect(
                throws:
                    Either<Async.Lifecycle.Error, GitHub.Organization.Repositories.Traversal.Error>
                    .right(.duplicate(.init(1)))
            ) {
                try await client.all(
                    request,
                    limit: bounds(pages: 2, items: 3),
                    duplicate: .reject,
                    order: .server
                )
            }
        }

        @Test("Traversal fails rather than returning an incomplete bounded result")
        func limit() async throws {
            let client = try self.client()
            await #expect(
                throws:
                    Either<Async.Lifecycle.Error, GitHub.Organization.Repositories.Traversal.Error>
                    .right(.pages)
            ) {
                try await client.all(
                    request(page: .first),
                    limit: bounds(pages: 1, items: 3),
                    duplicate: .preserve,
                    order: .server
                )
            }
        }

        @Test("Traversal observes cancellation before requesting a page")
        func cancellation() async throws {
            let client = try self.client()
            let task = Task {
                try await client.all(
                    request(page: .first),
                    limit: bounds(pages: 2, items: 3),
                    duplicate: .preserve,
                    order: .server
                )
            }
            task.cancel()

            await #expect(
                throws:
                    Either<Async.Lifecycle.Error, GitHub.Organization.Repositories.Traversal.Error>
                    .left(.cancelled)
            ) {
                try await task.value
            }
        }

        private func client() throws(Fixture.Failure) -> Client {
            let second = try self.page(2)
            return Client {
                (
                    request: GitHub.Organization.Repositories.Request
                ) async throws(Either<
                    Async.Lifecycle.Error, Page.Error
                >) in
                // swift-linter:disable:next raw value access
                // REASON: test-only fixture switching on the request's raw
                // page number to script per-page responses.
                switch request.page.rawValue {
                case 1:
                    return Page(
                        response: .init(
                            repositories: [
                                repository(id: 2, name: "beta"),
                                repository(id: 1, name: "alpha"),
                            ]
                        ),
                        next: self.request(page: second)
                    )

                case 2:
                    return Page(
                        response: .init(
                            repositories: [
                                repository(id: 1, name: "alpha-later"),
                                repository(id: 3, name: "gamma"),
                            ]
                        ),
                        next: nil
                    )

                default:
                    throw .right(.transport)
                }
            }
        }

        private func request(
            page: GitHub.Page.Number
        ) -> GitHub.Organization.Repositories.Request {
            .init(
                organization: .init("swiftlang"),
                type: .public,
                page: page,
                size: .maximum
            )
        }

        private func page(_ value: UInt) throws(Fixture.Failure) -> GitHub.Page.Number {
            guard let page = GitHub.Page.Number(rawValue: value) else { throw .unexpected }
            return page
        }

        private func bounds(
            pages: UInt,
            items: UInt
        ) throws(Fixture.Failure) -> GitHub.Organization.Repositories.Traversal.Limit {
            guard
                let pages = GitHub.Organization.Repositories.Traversal.Limit.Pages(rawValue: pages),
                let items = GitHub.Organization.Repositories.Traversal.Limit.Items(rawValue: items)
            else { throw .unexpected }
            return .init(pages: pages, items: items)
        }

        private func repository(
            id: UInt64,
            name: String
        ) -> GitHub.Repository.Summary {
            .init(
                id: .init(id),
                name: .init(name),
                archived: false,
                disabled: false,
                fork: false,
                visibility: .public
            )
        }
    }
}
