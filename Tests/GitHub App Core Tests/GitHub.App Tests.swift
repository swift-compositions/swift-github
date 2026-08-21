import Testing

@testable import GitHub_App

@Suite
struct `GitHub App Tests` {

    @Test
    func `parses a name=level permission`() throws {
        let permission = try GitHub.App.Permission(argument: "contents=read")
        #expect(permission.name == "contents")
        #expect(permission.level == "read")
        #expect(permission.field == "permissions[contents]=read")
    }

    @Test(arguments: [
        "contents", "contents=", "=read", "contents=read=write", "Contents=read",
        "contents=READ", "contents-x=read", "contents=read;rm -rf /", "",
    ])
    func `rejects a malformed permission`(argument: Swift.String) {

        #expect(throws: GitHub.App.Error.self) {
            try GitHub.App.Permission(argument: argument)
        }
    }

    @Test(arguments: ["swift-primitives", "swift-institute", "a", "swift-ietf"])
    func `accepts a GitHub organization login`(login: Swift.String) throws {
        try GitHub.App.validate(login)
    }

    @Test(arguments: ["", "-leading", "trailing-", "has space", "../escape", "a/b", "org?x"])
    func `rejects anything that is not a login`(login: Swift.String) {

        #expect(throws: GitHub.App.Error.self) {
            try GitHub.App.validate(login)
        }
    }

    @Test
    func `keys the cache by organization and permission set`() {
        let narrow = GitHub.App.Cache.key(
            organization: "swift-primitives",
            permissions: [.init(name: "contents", level: "read")]
        )
        let wide = GitHub.App.Cache.key(
            organization: "swift-primitives",
            permissions: []
        )

        #expect(narrow != wide)
        #expect(wide == "swift-primitives.all")
        #expect(narrow == "swift-primitives.contents-read")
    }

    @Test
    func `orders the permission set so the key is stable`() {
        let one = GitHub.App.Cache.key(
            organization: "swift-primitives",
            permissions: [
                .init(name: "metadata", level: "read"),
                .init(name: "contents", level: "read"),
            ]
        )
        let other = GitHub.App.Cache.key(
            organization: "swift-primitives",
            permissions: [
                .init(name: "contents", level: "read"),
                .init(name: "metadata", level: "read"),
            ]
        )

        #expect(one == other)
    }

    @Test
    func `reads GitHub's expiry as POSIX seconds`() throws {
        #expect(GitHub.App.Timestamp.seconds(from: "1970-01-01T00:00:00Z") == 0)
        #expect(GitHub.App.Timestamp.seconds(from: "2026-08-01T12:00:00Z") == 1_785_585_600)
        #expect(GitHub.App.Timestamp.seconds(from: "2024-02-29T00:00:00Z") == 1_709_164_800)
    }

    @Test(arguments: [
        "2026-08-01T12:00:00+01:00", "2026-08-01 12:00:00Z", "2026-08-01T12:00:00",
        "2026-13-01T00:00:00Z", "2026-08-01T24:00:00Z", "", "Z",
    ])
    func `refuses a timestamp it cannot read exactly`(value: Swift.String) {

        #expect(GitHub.App.Timestamp.seconds(from: value) == nil)
    }

    @Test
    func `holds a token back once it is inside the refresh margin`() {
        let token = GitHub.App.Token(value: "irrelevant", expires: 1_000)
        #expect(token.isUsable(at: 0))
        #expect(token.isUsable(at: 699))
        #expect(!token.isUsable(at: 700))
        #expect(!token.isUsable(at: 1_001))
    }

    @Test
    func `encodes the assertion's signing input as unpadded base64url`() {
        let input = GitHub.App.Assertion.signingInput(
            header: #"{"alg":"RS256","typ":"JWT"}"#,
            claims: #"{"iat":1,"exp":2,"iss":"7"}"#
        )
        let parts = input.split(separator: ".", omittingEmptySubsequences: false)
        #expect(parts.count == 2)

        #expect(!input.contains("="))
        #expect(!input.contains("+"))
        #expect(!input.contains("/"))
        #expect(parts[0] == "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9")
    }
}
