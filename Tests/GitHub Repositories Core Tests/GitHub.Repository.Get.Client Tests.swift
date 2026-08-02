import Testing

@testable import GitHub_Repositories

extension GitHub.Repository.Get {
    @Suite("GitHub.Repository.Get.Client.Unit")
    struct Core {
        @Test("Repository lookup preserves its typed failure")
        func failure() async {
            let client = Client<GitHub.Repository.Fixture.Failure> {
                (request: Request) async throws(GitHub.Repository.Fixture.Failure) -> Response in
                #expect(request.owner == .init("swiftlang"))
                #expect(request.repository == .init("swift"))
                throw .expected
            }

            let request = Request(
                owner: .init("swiftlang"),
                repository: .init("swift")
            )
            await #expect(throws: GitHub.Repository.Fixture.Failure.expected) {
                try await client.get(request)
            }
        }
    }
}
