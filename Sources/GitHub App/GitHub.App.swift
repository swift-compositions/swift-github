internal import Byte
internal import Either
private import Environment
public import File_System
public import GitHub_Standard

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
        keyPath: Swift.String?,
        name: File.Path.Component
    ) throws(Error) -> Self {
        let directory = try configurationDirectory(named: name)
        let service = name.description

        let path: Swift.String?
        if let keyPath, !keyPath.isEmpty {
            path = keyPath
        } else if let value = Environment.read(keyVariable), !value.isEmpty {
            path = value
        } else {
            path = nil
        }
        let key: Key
        if let path {
            do throws(Paths.Path.Error) {
                key = .file(File(try File.Path(path)))
            } catch {
                throw .key("the signing key path \(path) is not a usable path")
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
        do throws(Paths.Path.Error) {
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
