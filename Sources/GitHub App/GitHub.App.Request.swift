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
private import Environment
public import GitHub_Standard
internal import JSON
private import Process

extension GitHub.App {
    /// A single authenticated GitHub REST call, issued through `gh api`.
    ///
    /// ## Why `gh` and not an HTTP client
    ///
    /// The Institute has no public HTTP client package, and Foundation's
    /// `URLSession` is barred. This is a Swift adapter over the `Process`
    /// product already in this manifest, not shell automation — the two calls
    /// it makes are fixed, and nothing it produces is hand-maintained.
    ///
    /// ## Why the credential is carried twice
    ///
    /// `GH_TOKEN` alone does not work here, and the failure is not obvious:
    /// `gh` sends it as `Authorization: token <value>`, and GitHub answers an
    /// application assertion presented under that scheme with *"A JSON web
    /// token could not be decoded"* — a message that reads like a malformed
    /// JWT rather than a wrong scheme, and sends the reader looking at their
    /// signing code. Application assertions are accepted only as `Bearer`, so
    /// the scheme is set explicitly.
    ///
    /// `GH_TOKEN` is still set, because `gh api` refuses to run at all without
    /// a credential it can resolve; the explicit header then decides what
    /// actually goes on the wire. The child also gets a *complete* environment
    /// snapshot, because `gh` needs `HOME` and `PATH` to function.
    ///
    /// The consequence is that the assertion — never the installation token —
    /// appears in the child's `argv` for the length of one call. It is a
    /// nine-minute credential that can do nothing but ask for the tokens this
    /// command was invoked to mint, which is the narrower exposure of the two
    /// available; the minted token itself never leaves this process except on
    /// stdout and in the mode-600 cache.
    public enum Request {}
}

extension GitHub.App.Request {
    /// Issues `gh api`, returning the parsed response body.
    ///
    /// - Parameters:
    ///   - method: The HTTP method.
    ///   - path: The API path, e.g. `/orgs/swift-primitives/installation`.
    ///   - fields: `-f name=value` payload fields; nested keys use
    ///     `outer[inner]=value`.
    ///   - token: The credential, placed in the child's `GH_TOKEN`.
    static func json(
        method: Swift.String,
        path: Swift.String,
        fields: [Swift.String] = [],
        token: Swift.String
    ) throws(GitHub.App.Error) -> JSON {
        var arguments: [Swift.String] = [
            "gh", "api",
            "--method", method,
            "-H", "Accept: application/vnd.github+json",
            "-H", "X-GitHub-Api-Version: 2022-11-28",
            "-H", "Authorization: Bearer \(token)",
        ]
        for field in fields {
            arguments.append("-f")
            arguments.append(field)
        }
        arguments.append(path)

        var environment = Environment.read.all()
        environment["GH_TOKEN"] = token
        // `gh` prefers its own stored credential over GH_TOKEN when the host
        // is configured with one; GH_CONFIG_DIR cannot be cleared without
        // losing the host configuration, so unset the competing variable
        // instead and let GH_TOKEN win.
        environment.removeValue(forKey: "GITHUB_TOKEN")

        let output: Process.Output
        do throws(Process.Error) {
            output = try Process.Spawn.run(
                .init(
                    executable: "/usr/bin/env",
                    arguments: arguments,
                    environment: environment,
                    stdout: .pipe,
                    stderr: .pipe
                )
            )
        } catch {
            throw .transport("cannot execute gh: \(error)")
        }

        guard case .exited(let code) = output.status else {
            throw .transport("gh did not exit normally: \(output.status)")
        }
        let stdout = output.stdout ?? []
        guard code == 0 else {
            // The body carries GitHub's own message, which is the useful part
            // of a 403 or 404 here. It never contains the credential.
            let message = Swift.String(decoding: stdout, as: Swift.UTF8.self).trimmed()
            let diagnostic = Swift.String(decoding: output.stderr ?? [], as: Swift.UTF8.self)
                .trimmed()
            throw .response(
                "gh api \(method) \(path) exited \(code)"
                    + (message.isEmpty ? "" : ": \(message)")
                    + (diagnostic.isEmpty || !message.isEmpty ? "" : ": \(diagnostic)")
            )
        }
        guard !stdout.isEmpty else {
            throw .response("gh api \(method) \(path) succeeded and captured no output")
        }
        do throws(JSON.Error) {
            return try JSON.parse(Swift.String(decoding: stdout, as: Swift.UTF8.self))
        } catch {
            throw .response("gh api \(method) \(path) returned an unparseable body: \(error)")
        }
    }
}
