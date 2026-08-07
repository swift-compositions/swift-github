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

extension GitHub.App {
    /// Everything that can go wrong minting an installation token.
    ///
    /// **No case carries key material or a resolved key location.** The signing
    /// key is fleet-password-equivalent, and its path identifies the operator's
    /// machine; a diagnostic that names either turns every error report, log,
    /// and pasted transcript into a disclosure. Cases therefore describe *what*
    /// failed, never *with what* or *from where*.
    public enum Error: Swift.Error, Equatable, CustomStringConvertible {
        /// No application identity could be resolved.
        case identity
        /// No signing key could be resolved, or more than one candidate exists.
        case key(Swift.String)
        /// The key file could not be read.
        case unreadable
        /// The key file is not a PEM-armoured private key this can import.
        case malformedKey
        /// The platform has no signing facility this build can reach.
        case unsupportedPlatform
        /// Signing failed inside the platform's key facility.
        case signing(Swift.String)
        /// A `--permission` argument was not `name=level`.
        case permission(Swift.String)
        /// The organization name was empty or not a usable path component.
        case organization(Swift.String)
        /// The GitHub request could not be issued at all.
        case transport(Swift.String)
        /// GitHub answered, and the answer was a failure or unusable.
        case response(Swift.String)
        /// The token cache could not be read or written.
        case cache(Swift.String)
    }
}

extension GitHub.App.Error {
    public var description: Swift.String {
        switch self {
        case .identity:
            "no GitHub App identity is configured; pass --app-id, set GITHUB_APP_ID, "
                + "or write the identity file in the configuration directory"
        case .key(let message): message
        case .unreadable: "the configured signing key could not be read"
        case .malformedKey: "the configured signing key is not a PEM-armoured RSA private key"
        case .unsupportedPlatform:
            "this platform has no signing facility reachable from this build"
        case .signing(let message): "cannot sign the application assertion: \(message)"
        case .permission(let message): message
        case .organization(let message): message
        case .transport(let message): message
        case .response(let message): message
        case .cache(let message): message
        }
    }
}
