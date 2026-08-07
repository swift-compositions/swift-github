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
internal import Either_Primitives
private import Environment
public import File_System
public import GitHub_Standard

extension GitHub {
    /// A GitHub App the operator has installed a signing key for.
    ///
    /// The three things this needs — an application identity, a signing key,
    /// and somewhere to cache tokens — are all resolved at run time. Nothing
    /// is compiled in: even the *name of the directory* under the operator's
    /// configuration root is the caller's to supply; which application it
    /// holds a key for, and which key, is the operator's business and never
    /// this repository's.
    public struct App: Sendable {
        /// The application's numeric identity, used as the assertion issuer.
        public let identity: Swift.String

        /// The PEM-armoured private key file. Never rendered into output.
        public let key: File

        /// The directory holding the key, the identity file, and the cache.
        public let directory: File.Directory

        public init(identity: Swift.String, key: File, directory: File.Directory) {
            self.identity = identity
            self.key = key
            self.directory = directory
        }
    }
}

extension GitHub.App {
    /// The file holding the application's numeric identity, when it is not
    /// supplied by argument or environment.
    public static let identityFileName: File.Path.Component = "application-id"

    /// The environment variable consulted for the application identity.
    public static let identityVariable = "GITHUB_APP_ID"

    /// The environment variable consulted for the signing key location.
    public static let keyVariable = "GITHUB_APP_PRIVATE_KEY_PATH"
}

extension GitHub.App {
    /// Resolves the application from explicit arguments, the environment, and
    /// the operator's configuration directory, in that order.
    ///
    /// - Parameters:
    ///   - identity: `--app-id`, when supplied.
    ///   - keyPath: `--key`, when supplied.
    ///   - configurationDirectoryName: The name of the directory under the
    ///     operator's `~/.config` holding the key, the identity file, and the
    ///     token cache. Names where an operator keeps bot credentials, never
    ///     which credentials exist or what they can do.
    /// - Throws: ``GitHub/App/Error`` when no identity or exactly one
    ///   key cannot be resolved. No thrown message names a filesystem location.
    public static func resolve(
        identity argument: Swift.String?,
        keyPath: Swift.String?,
        configurationDirectoryName: File.Path.Component
    ) throws(Error) -> Self {
        let directory = try configurationDirectory(named: configurationDirectoryName)

        let identity: Swift.String
        if let argument, !argument.isEmpty {
            identity = argument
        } else if let value = Environment.read(identityVariable), !value.isEmpty {
            identity = value
        } else {
            let file = directory[file: identityFileName]
            guard file.stat.exists else { throw .identity }
            let contents: Swift.String
            do throws(Error) {
                contents = try read(file)
            } catch {
                throw .identity
            }
            let trimmed = contents.trimmed()
            guard !trimmed.isEmpty else { throw .identity }
            identity = trimmed
        }
        guard identity.allSatisfy(\.isNumber) else { throw .identity }

        let key: File
        if let keyPath, !keyPath.isEmpty {
            do throws(Paths.Path.Error) {
                key = File(try File.Path(keyPath))
            } catch {
                throw .key("the --key argument is not a usable path")
            }
        } else if let value = Environment.read(keyVariable), !value.isEmpty {
            do throws(Paths.Path.Error) {
                key = File(try File.Path(value))
            } catch {
                throw .key("\(keyVariable) is not a usable path")
            }
        } else {
            key = try soleKey(in: directory)
        }
        guard key.stat.exists else {
            throw .key("the configured signing key does not exist")
        }

        return .init(identity: identity, key: key, directory: directory)
    }

    /// `~/.config/<name>`.
    static func configurationDirectory(named name: File.Path.Component) throws(Error)
        -> File.Directory
    {
        guard let home = Environment.read("HOME"), !home.isEmpty else {
            throw .key("HOME is not available, so the configuration directory cannot be resolved")
        }
        let root: File.Directory
        do throws(Paths.Path.Error) {
            root = try File.Directory(validating: home)
        } catch {
            throw .key("HOME is not a usable path")
        }
        return root[directory: ".config"][directory: name]
    }

    /// The one `.pem` in the configuration directory.
    ///
    /// Ambiguity is an error rather than a guess: a rolled key sits beside its
    /// predecessor, and silently signing with whichever sorts first would fail
    /// only once the old key is revoked — long after the choice was made. The
    /// diagnostic reports *how many* candidates were found and never their
    /// names, which encode dates and machine layout.
    static func soleKey(in directory: File.Directory) throws(Error) -> File {
        guard directory.stat.exists else {
            throw .key("the configuration directory does not exist")
        }
        let entries: [File.Directory.Entry]
        do throws(File.Directory.Contents.Error) {
            entries = try File.Directory.Contents.list(at: directory)
        } catch {
            throw .key("the configuration directory could not be listed")
        }
        let candidates = entries.compactMap { entry -> File? in
            guard entry.type == .file else { return nil }
            let name = entry.name.description
            guard name.hasSuffix(".pem") else { return nil }
            do throws(Paths.Path.Component.Error) {
                return directory[file: try File.Path.Component(name)]
            } catch {
                return nil
            }
        }
        guard let key = candidates.first, candidates.count == 1 else {
            throw .key(
                candidates.isEmpty
                    ? "no signing key was found in the configuration directory; "
                        + "pass --key or set \(keyVariable)"
                    : "\(candidates.count) candidate signing keys are installed; "
                        + "pass --key to choose one"
            )
        }
        return key
    }

    static func read(_ file: File) throws(Error) -> Swift.String {
        do throws(Either<File.System.Read.Full.Error, Never>) {
            return try file.read.full { bytes in
                var storage = [Byte]()
                storage.reserveCapacity(bytes.count)
                for index in bytes.indices { storage.append(bytes[index]) }
                return Swift.String(decoding: storage, as: Swift.UTF8.self)
            }
        } catch {
            throw .unreadable
        }
    }
}

extension Swift.String {
    /// Drops leading and trailing ASCII whitespace and newlines.
    func trimmed() -> Self {
        var slice = Substring(self)
        while let first = slice.first,
            first == " " || first == "\n" || first == "\r" || first == "\t"
        {
            slice = slice.dropFirst()
        }
        while let last = slice.last, last == " " || last == "\n" || last == "\r" || last == "\t" {
            slice = slice.dropLast()
        }
        return Self(slice)
    }
}
