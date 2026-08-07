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
    /// One narrowing of a minted token, mirroring CI's `permission-<name>`
    /// inputs.
    ///
    /// A token minted with no permissions carries everything the installation
    /// was granted. Narrowing is therefore the discipline, not the exception:
    /// a read that only needs `contents=read` should never hold a credential
    /// that can administer a repository.
    public struct Permission: Sendable, Equatable, Comparable {
        public let name: Swift.String
        public let level: Swift.String

        public init(name: Swift.String, level: Swift.String) {
            self.name = name
            self.level = level
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name ? lhs.level < rhs.level : lhs.name < rhs.name
        }
    }
}

extension GitHub.App.Permission {
    /// Parses a `name=level` argument.
    ///
    /// Both halves are constrained to the shape GitHub's API uses — lowercase
    /// letters and underscores — so a malformed flag is rejected here rather
    /// than becoming an opaque 422 from the mint call, or worse, a cache file
    /// name containing whatever the shell passed through.
    public init(argument: Swift.String) throws(GitHub.App.Error) {
        let halves = argument.split(separator: "=", omittingEmptySubsequences: false)
        guard halves.count == 2 else {
            throw .permission("--permission expects name=level; got \(argument)")
        }
        let name = Swift.String(halves[0])
        let level = Swift.String(halves[1])
        guard Self.isWellFormed(name), Self.isWellFormed(level) else {
            throw .permission(
                "--permission name and level must be lowercase words; got \(argument)"
            )
        }
        self.init(name: name, level: level)
    }

    static func isWellFormed(_ value: Swift.String) -> Swift.Bool {
        !value.isEmpty
            && value.allSatisfy { $0 == "_" || ($0.isLetter && $0.isLowercase && $0.isASCII) }
    }
}

extension GitHub.App.Permission {
    /// The `-f` field argument this permission contributes to the mint call.
    var field: Swift.String { "permissions[\(name)]=\(level)" }
}
