internal import Byte
internal import Byte_Standard_Library_Integration
internal import Either
private import Environment
public import File_System
public import GitHub_Standard

extension GitHub {

    public struct App: Sendable {

        public let identity: Swift.String

        public let key: File

        public let directory: File.Directory

        public init(identity: Swift.String, key: File, directory: File.Directory) {
            self.identity = identity
            self.key = key
            self.directory = directory
        }
    }
}

extension GitHub.App {

    public static let identityFileName: File.Path.Component = "application-id"

    public static let identityVariable = "GITHUB_APP_ID"

    public static let keyVariable = "GITHUB_APP_PRIVATE_KEY_PATH"
}

extension GitHub.App {

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

    static func configurationDirectory(
        named name: File.Path.Component
    ) throws(Error)
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
