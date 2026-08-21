public import File_System
public import GitHub_Standard
internal import JSON

extension GitHub.App {

    public struct Cache: Sendable {
        public let directory: File.Directory

        public init(directory: File.Directory) {
            self.directory = directory
        }
    }
}

extension GitHub.App.Cache {

    public func file(
        organization: Swift.String,
        permissions: [GitHub.App.Permission]
    ) -> File {

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
