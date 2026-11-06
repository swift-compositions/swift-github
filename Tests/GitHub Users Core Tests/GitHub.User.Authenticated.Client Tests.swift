import Tagged
import Testing

@testable import GitHub_Users

enum `GitHub.User.Authenticated Tests` {
    typealias Emails = GitHub.User.Authenticated.Emails
    typealias Get = GitHub.User.Authenticated.Get
}

extension `GitHub.User.Authenticated Tests` {
    @Suite("GitHub.User.Authenticated.Client.Unit")
    struct Core {
        @Test("Authenticated-user lookup preserves its typed failure")
        func get() async {
            let client = Get.Client<GitHub.User.Fixture.Failure> {
                (request: Get.Request) async throws(GitHub.User.Fixture.Failure) in
                #expect(request.accessToken == "access-token")
                throw .expected
            }

            await #expect(throws: GitHub.User.Fixture.Failure.expected) {
                try await client.get(.init(accessToken: "access-token"))
            }
        }

        @Test("Authenticated-user email listing preserves its typed failure")
        func emails() async {
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
