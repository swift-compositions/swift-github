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
public import JSON

extension GitHub.App {
    /// A minted installation access token and the instant it stops working.
    public struct Token: Sendable, Equatable, JSON.Serializable {
        /// The credential. Written to stdout, to a mode-600 cache file, and
        /// nowhere else — never to a log, a diagnostic, or a process argument.
        public let value: Swift.String

        /// Expiry, as seconds since the POSIX epoch, taken from GitHub's own
        /// `expires_at` rather than from a local clock reading at mint time.
        public let expires: Swift.Int64

        public init(value: Swift.String, expires: Swift.Int64) {
            self.value = value
            self.expires = expires
        }
    }
}

extension GitHub.App.Token {
    /// How much life a cached token must have left to be reused.
    ///
    /// Five minutes covers the round trip of whatever the caller is about to
    /// do with it, plus the clock skew between this machine and GitHub — the
    /// comparison is against a local reading, so a machine running fast would
    /// otherwise hand out a credential that expires mid-command.
    public static let refreshMargin: Swift.Int64 = 300

    /// Whether this token has enough life left to hand out at `now`.
    public func isUsable(at now: Swift.Int64) -> Swift.Bool {
        expires - now > Self.refreshMargin
    }
}

extension GitHub.App.Token {
    public static func serialize(_ value: Self) -> JSON {
        [
            "token": value.value.json,
            "expires": Swift.Int(value.expires).json,
        ]
    }

    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
        guard let object = json.dictionary else {
            throw .typeMismatch(expected: "object", got: "non-object")
        }
        guard let token = object["token"] else { throw .missingKey("token") }
        guard let expires = object["expires"] else { throw .missingKey("expires") }
        return .init(
            value: try Swift.String.deserialize(token),
            expires: Swift.Int64(try Swift.Int.deserialize(expires))
        )
    }
}
