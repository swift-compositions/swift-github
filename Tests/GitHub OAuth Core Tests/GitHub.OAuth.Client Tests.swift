import RFC_3986
import Testing

@testable import GitHub_OAuth

extension GitHub.OAuth {
    @Suite("GitHub.OAuth.Client.Unit")
    struct Core {
        @Test("Authorization preserves its typed failure")
        func authorization() throws(RFC_3986.Error) {
            let client = Authorization.Client<Fixture.Failure> {
                (request: Authorization.Request) throws(Fixture.Failure) in
                #expect(request.clientID == "client-id")
                throw .expected
            }
            let request = Authorization.Request(
                clientID: "client-id",
                redirectURI: try RFC_3986.URI("https://example.com/callback"),
                scopes: ["read:user"],
                state: "state"
            )

            #expect(throws: Fixture.Failure.expected) {
                try client.authorize(request)
            }
        }

        @Test("Token exchange preserves its typed failure")
        func token() async {
            let client = Token.Exchange.Client<Fixture.Failure> {
                (request: Token.Exchange.Request) async throws(Fixture.Failure) in
                #expect(request.code == "code")
                throw .expected
            }
            let request = Token.Exchange.Request(
                clientID: "client-id",
                clientSecret: "client-secret",
                code: "code"
            )

            await #expect(throws: Fixture.Failure.expected) {
                try await client.exchange(request)
            }
        }
    }
}
