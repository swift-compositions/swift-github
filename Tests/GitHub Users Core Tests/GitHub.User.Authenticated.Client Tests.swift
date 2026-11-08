import Tagged
import Testing

@testable import GitHub_Users

enum `GitHub.User.Authenticated Tests` {
    typealias Emails = GitHub.User.Authenticated.Emails
    typealias Get = GitHub.User.Authenticated.Get
}

extension `GitHub.User.Authenticated Tests` {
    @Suite
    struct Core {
        @Test
        func `Authenticated-user lookup preserves its typed failure`() async {
            let client = Get.Client<GitHub.User.Fixture.Failure> {
                (request: Get.Request) async throws(GitHub.User.Fixture.Failure) in
                #expect(request.accessToken == "access-token")
                throw .expected
            }

            await #expect(throws: GitHub.User.Fixture.Failure.expected) {
                try await client.get(.init(accessToken: "access-token"))
            }
        }

        @Test
        func `Authenticated-user email listing preserves its typed failure`() async {
            let client = Emails.List.Client<GitHub.User.Fixture.Failure> {
                (request: Emails.List.Request) async throws(GitHub.User.Fixture.Failure) in
                #expect(request.accessToken == "access-token")
                throw .expected
            }

            await #expect(throws: GitHub.User.Fixture.Failure.expected) {
                try await client.list(.init(accessToken: "access-token"))
            }
        }
    }
}
