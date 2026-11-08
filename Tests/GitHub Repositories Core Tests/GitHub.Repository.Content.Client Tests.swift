import Tagged
import Testing

@testable import GitHub_Repositories

enum `GitHub.Repository.Content Tests` {
    typealias Client = GitHub.Repository.Content.Client
    typealias Path = GitHub.Repository.Content.Path
    typealias Request = GitHub.Repository.Content.Request
    typealias Response = GitHub.Repository.Content.Response
}

extension `GitHub.Repository.Content Tests` {
    @Suite
    struct Core {
        @Test
        func `The client preserves present and absent provider content`() async throws {
            let client = Client<Fixture.Failure> { request in
                request.repository.underlying == "swift-package"
                    ? .init(kind: .file)
                    : nil
            }

            #expect(try await client.get(self.request("swift-package"))?.kind == .file)
            #expect(try await client.get(self.request("not-a-package")) == nil)
        }

        @Test
        func `The client preserves typed failures`() async {
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
                organization: .init("swift-compositions"),
                repository: .init(repository),
                path: path
            )
        }

        enum Fixture {}
    }
}

extension `GitHub.Repository.Content Tests`.Core.Fixture {
    enum Failure: Swift.Error, Equatable, Sendable {
        case unexpected
    }
}
