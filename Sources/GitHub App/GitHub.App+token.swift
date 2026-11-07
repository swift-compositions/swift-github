public import GitHub_Standard
internal import JSON

extension GitHub.App {

    public func token(
        organization: Swift.String,
        permissions: [Permission],
        now: Swift.Int64 = GitHub.App.Clock.now()
    ) throws(Error) -> (token: Token, cached: Swift.Bool) {
        try Self.validate(organization)
        let cache = Cache(directory: directory)
        if let cached = cache.read(organization: organization, permissions: permissions, at: now) {
            return (cached, true)
        }

        let assertion = try Assertion(app: self, now: now)
        let installation = try installation(organization: organization, assertion: assertion)
        let token = try mint(
            installation: installation,
            permissions: permissions,
            assertion: assertion
        )
        try cache.write(token, organization: organization, permissions: permissions)
        return (token, false)
    }

    static func validate(_ organization: Swift.String) throws(Error) {
        guard !organization.isEmpty, organization.count <= 39 else {
            throw .organization("--org must be a GitHub organization login")
        }
        guard
            organization.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }),
            organization.first != "-",
            organization.last != "-"
        else {
            throw .organization(
                "--org must be a GitHub organization login; got \(organization)"
            )
        }
    }

    func installation(
        organization: Swift.String,
        assertion: Assertion
    ) throws(Error) -> Swift.String {
        let response = try GitHub.App.Request.json(
            method: "GET",
            path: "/orgs/\(organization)/installation",
            token: assertion.compact
        )
        let identifier: Swift.Int
        do throws(JSON.Error) {
            identifier = try Swift.Int.deserialize(response["id"])
        } catch {
            throw .response(
                "the application is not installed on \(organization), "
                    + "or the installation carries no identity"
            )
        }
        return Swift.String(identifier)
    }

    func mint(
        installation: Swift.String,
        permissions: [Permission],
        assertion: Assertion
    ) throws(Error) -> Token {
        let response = try GitHub.App.Request.json(
            method: "POST",
            path: "/app/installations/\(installation)/access_tokens",
            fields: permissions.sorted().map(\.field),
            token: assertion.compact
        )
        let value: Swift.String
        let expiry: Swift.String
        do throws(JSON.Error) {
            value = try Swift.String.deserialize(response["token"])
            expiry = try Swift.String.deserialize(response["expires_at"])
        } catch {
            throw .response("GitHub's answer carried no token and expiry pair")
        }
        guard !value.isEmpty else {
            throw .response("GitHub returned no token for the installation")
        }
        guard let expires = GitHub.App.Timestamp.seconds(from: expiry) else {
            throw .response("GitHub returned no usable expiry for the minted token")
        }
        return .init(value: value, expires: expires)
    }
}
