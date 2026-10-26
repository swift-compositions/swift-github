public import File_System
public import GitHub_Standard

extension GitHub.App {

    /// Where the application's signing key lives: a PEM file named on the command line or in
    /// the environment, or the operator's login keychain.
    public enum Key: Sendable, Equatable {

        case file(File)

        case keychain(service: Swift.String)
    }
}

extension GitHub.App.Key {

    /// The PEM-armoured private key.
    func pem() throws(GitHub.App.Error) -> Swift.String {
        switch self {
        case .file(let file):
            guard file.stat.exists else {
                throw .key("the configured signing key \(file.path) does not exist")
            }
            return try GitHub.App.read(file)

        case .keychain(let service):
            return try GitHub.App.Keychain.secret(service: service)
        }
    }
}
