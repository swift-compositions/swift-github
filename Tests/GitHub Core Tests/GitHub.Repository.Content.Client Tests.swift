import Testing

@testable import GitHub

extension GitHub.Repository.Content {
    @Suite("GitHub.Repository.Content.Client.Unit")
    struct Core {
        @Test("The client preserves present and absent provider content")
        func presence() async throws {
            let client = Client<Fixture.Failure> { request in
                request.repository.underlying == "swift-package"
                    ? .init(kind: .file)
                    : nil
            }

            #expect(try await client.get(self.request("swift-package"))?.kind == .file)
            #expect(try await client.get(self.request("not-a-package")) == nil)
        }

        @Test("The client preserves typed failures")
        func failure() async {
            let client = Client<Fixture.Failure> {
                (_: Request) async throws(Fixture.Failure) -> Response? in
                throw .unexpected
            }

            await #expect(throws: Fixture.Failure.unexpected) {
                try await client.get(request("swift-package"))
            }
        }

        private func request(_ repository: String) throws(Fixture.Failure) -> Request {
            guard let path = Path(segments: ["Package.swift"]) else { throw .unexpected }
            return .init(
                organization: .init("swift-foundations"),
                repository: .init(repository),
                path: path
            )
        }

        enum Fixture {}
    }
}

extension GitHub.Repository.Content.Core.Fixture {
    enum Failure: Swift.Error, Equatable, Sendable {
        case unexpected
    }
}
