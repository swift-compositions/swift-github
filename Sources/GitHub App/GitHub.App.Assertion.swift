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

internal import Byte_Primitives
internal import Byte_Primitives_Standard_Library_Integration
internal import File_System
internal import GitHub_Standard
internal import RFC_4648
internal import Signature

extension GitHub.App {
    /// The short-lived RS256 JWT that authenticates *the application* — the
    /// credential that buys an installation token, and nothing else.
    ///
    /// It is never cached and never leaves this process except as an
    /// `Authorization` header on the two mint requests.
    struct Assertion {
        let compact: Swift.String
    }
}

extension GitHub.App.Assertion {
    /// `iat` is backdated a minute and `exp` is nine minutes out.
    ///
    /// GitHub rejects an assertion whose `iat` is in *its* future, and the two
    /// clocks are not the same clock. Backdating absorbs the skew that would
    /// otherwise make minting fail intermittently on a machine running a
    /// second fast. Nine minutes stays inside the ten-minute ceiling with room
    /// for the same skew at the other end.
    static let backdate: Swift.Int64 = 60
    static let lifetime: Swift.Int64 = 540
}

extension GitHub.App.Assertion {
    /// Builds and signs the assertion for `app` at `now`.
    init(
        app: GitHub.App,
        now: Swift.Int64
    ) throws(GitHub.App.Error) {
        let pem = try GitHub.App.read(app.key)
        let key: Signature.RSA.Key
        do {
            key = try Signature.RSA.Key(pem: pem)
        } catch {
            throw .malformedKey
        }
        let issued = now - Self.backdate
        let expires = issued + Self.lifetime
        try self.init(
            header: #"{"alg":"RS256","typ":"JWT"}"#,
            claims: #"{"iat":\#(issued),"exp":\#(expires),"iss":"\#(app.identity)"}"#,
            key: key
        )
    }

    /// The signing seam, taken separately so the encoding can be tested
    /// without a key facility and without a key.
    init(
        header: Swift.String,
        claims: Swift.String,
        key: Signature.RSA.Key
    ) throws(GitHub.App.Error) {
        let signed = Self.signingInput(header: header, claims: claims)
        let signature: [Byte]
        do {
            signature = try Signature.RS256.sign(message: [Byte](signed.utf8), key: key)
        } catch {
            switch error {
            case .malformedKey: throw .malformedKey
            case .unsupportedPlatform: throw .unsupportedPlatform
            case .signing(let message): throw .signing(message)
            }
        }
        self.compact = signed + "." + signature.base64.url.encoded()
    }

    static func signingInput(header: Swift.String, claims: Swift.String) -> Swift.String {
        [Byte](header.utf8).base64.url.encoded()
            + "." + [Byte](claims.utf8).base64.url.encoded()
    }
}
