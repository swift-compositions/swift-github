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

public import File_System
public import GitHub_Standard
internal import JSON

extension GitHub.App {
    /// Mode-600 storage for minted tokens, keyed by organization and by the
    /// exact permission set they were narrowed to.
    ///
    /// Keying on the permission set matters as much as keying on the
    /// organization: a token narrowed to `contents=read` and a token with the
    /// installation's full grant are different credentials, and handing the
    /// second one back to a caller that asked for the first would quietly widen
    /// every subsequent request made with it.
    public struct Cache: Sendable {
        public let directory: File.Directory

        public init(directory: File.Directory) {
            self.directory = directory
        }
    }
}

extension GitHub.App.Cache {
    /// The cache file for one organization and permission set.
    ///
    /// The name is readable rather than hashed — this directory is one an
    /// operator is expected to inspect and delete from — and every component
    /// is drawn from already-validated input, so no shell-supplied text can
    /// reach a path.
    public func file(
        organization: Swift.String,
        permissions: [GitHub.App.Permission]
    ) -> File {
        // Every component is drawn from validated input, so the component
        // cannot fail to construct; a fallback name would only hide a defect
        // in that validation.
        let name = "token.\(Self.key(organization: organization, permissions: permissions)).json"
        do throws(Paths.Path.Component.Error) {
            return directory[file: try File.Path.Component(name)]
        } catch {
            return directory[file: "token.invalid.json"]
        }
    }

    static func key(
        organization: Swift.String,
        permissions: [GitHub.App.Permission]
    ) -> Swift.String {
        let narrowing = permissions.sorted().map { "\($0.name)-\($0.level)" }
            .joined(separator: ".")
        return narrowing.isEmpty ? "\(organization).all" : "\(organization).\(narrowing)"
    }
}

extension GitHub.App.Cache {
    /// The cached token for this key, if one is stored and still usable.
    ///
    /// A malformed or unreadable entry is *not* an error: the cache is an
    /// optimization, and failing the command because a stale file cannot be
    /// decoded would make a purely local hiccup look like a GitHub outage.
    public func read(
        organization: Swift.String,
        permissions: [GitHub.App.Permission],
        at now: Swift.Int64
    ) -> GitHub.App.Token? {
        let file = file(organization: organization, permissions: permissions)
        guard file.stat.exists else { return nil }
        let contents: Swift.String
        do throws(GitHub.App.Error) {
            contents = try GitHub.App.read(file)
        } catch {
            return nil
        }
        do throws(JSON.Error) {
            let token = try GitHub.App.Token(jsonString: contents)
            return token.isUsable(at: now) ? token : nil
        } catch {
            return nil
        }
    }

    /// Stores `token`, readable and writable by its owner alone.
    ///
    /// The permissions are set after the write rather than trusted from the
    /// process umask — a token written world-readable is the same disclosure as
    /// printing it into a log, and a umask is ambient machine state this must
    /// not depend on.
    public func write(
        _ token: GitHub.App.Token,
        organization: Swift.String,
        permissions: [GitHub.App.Permission]
    ) throws(GitHub.App.Error) {
        do throws(File.System.Create.Directory.Error) {
            try directory.create.recursive()
        } catch {
            throw .cache("cannot create the token cache directory: \(error)")
        }
        do throws(File.System.Metadata.Permissions.Error) {
            try File.System.Metadata.Permissions.set(
                [.ownerRead, .ownerWrite, .ownerExecute],
                at: directory.path
            )
        } catch {
            throw .cache("cannot restrict the token cache directory: \(error)")
        }

        let file = file(organization: organization, permissions: permissions)
        do throws(File.System.Write.Atomic.Error) {
            try file.write.atomic(token.jsonString())
        } catch {
            throw .cache("cannot write the token cache entry: \(error)")
        }
        do throws(File.System.Metadata.Permissions.Error) {
            try File.System.Metadata.Permissions.set([.ownerRead, .ownerWrite], at: file.path)
        } catch {
            throw .cache("cannot restrict the token cache entry: \(error)")
        }
    }
}
