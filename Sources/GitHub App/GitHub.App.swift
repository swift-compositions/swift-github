internal import Byte
internal import Either
private import Environment
public import File_System
public import GitHub_Standard
internal import JSON

extension GitHub {

    public struct App: Sendable {

        public let identity: Swift.String

        public let key: Key

        public let directory: File.Directory

        public init(identity: Swift.String, key: Key, directory: File.Directory) {
            self.identity = identity
            self.key = key
            self.directory = directory
        }
    }
}

extension GitHub.App {

    public static let identityVariable = "GITHUB_APP_ID"

    public static let keyVariable = "GITHUB_APP_PRIVATE_KEY_PATH"
}

extension GitHub.App {

    /// Resolves the identity and signing key. The key is the `keyPath` argument, else the file
    /// `GITHUB_APP_PRIVATE_KEY_PATH` names, else the login-keychain item whose service is
    /// `name`. The identity is the argument, else `GITHUB_APP_ID`, else that item's account.
    /// `name` also names the token cache directory under `~/.config`.
    public static func resolve(
        identity argument: Swift.String?,
        keyPath: File.Path?,
        name: File.Path.Component
    ) throws(Error) -> Self {
        let directory = try configurationDirectory(named: name)
        let service = name.description

        let key: Key
        if let keyPath {
            key = .file(File(keyPath))
        } else if let value = Environment.read(keyVariable), !value.isEmpty {
            do throws(Path::Path.Error) {
                key = .file(File(try File.Path(value)))
            } catch {
                throw .key("the signing key path \(value) is not a usable path")
            }
        } else {
            key = .keychain(service: service)
        }

        let identity: Swift.String
        if let argument, !argument.isEmpty {
            identity = argument
        } else if let value = Environment.read(identityVariable), !value.isEmpty {
            identity = value
        } else if case .keychain = key {
            identity = try Keychain.identity(service: service)
        } else {
            throw .identity
        }
        guard identity.allSatisfy(\.isNumber) else { throw .identity }

        return .init(identity: identity, key: key, directory: directory)
    }

    static func configurationDirectory(
        named name: File.Path.Component
    ) throws(Error)
        -> File.Directory
    {
        guard let home = Environment.read("HOME"), !home.isEmpty else {
            throw .key("HOME is not available, so the token cache directory cannot be resolved")
        }
        let root: File.Directory
        do throws(Path::Path.Error) {
            root = try File.Directory(validating: home)
        } catch {
            throw .key("HOME is not a usable path")
        }
        return root[directory: ".config"][directory: name]
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
