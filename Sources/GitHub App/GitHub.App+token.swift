// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-github open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-github project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import GitHub_Standard
internal import JSON

extension GitHub.App {
    /// The installation token for `organization`, from the cache when one is
    /// still good and from GitHub otherwise.
    ///
    /// The mint is two calls under an application assertion: the installation
    /// for the organization, then a token for that installation. Both are
    /// needed every time a mint happens — the installation identity is not
    /// cached separately, because caching it saves one request an hour and
    /// adds a second thing that can go stale silently.
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

    /// Rejects anything that is not a GitHub login.
    ///
    /// This value reaches both a URL path and a cache file name. Validating it
    /// once, here, is what keeps either from being something else.
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

    /// The installation identity of this application on `organization`.
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

    /// Exchanges the assertion for an installation access token.
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
