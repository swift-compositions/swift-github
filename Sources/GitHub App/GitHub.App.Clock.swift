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

#if canImport(Darwin)
    private import Darwin
#elseif canImport(Glibc)
    private import Glibc
#elseif canImport(Musl)
    private import Musl
#endif

extension GitHub.App {
    /// Wall-clock seconds since the POSIX epoch.
    ///
    /// A JWT's `iat` and `exp` are absolute instants agreed with a remote
    /// party, so a monotonic clock cannot serve here — `ContinuousClock`, a
    /// clock made for measurement, has no relationship to GitHub's calendar
    /// at all.
    public enum Clock {}
}

extension GitHub.App.Clock {
    public static func now() -> Swift.Int64 {
        Swift.Int64(unsafe time(nil))
    }
}
