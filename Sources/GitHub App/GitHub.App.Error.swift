public import GitHub_Standard

extension GitHub.App {

    public enum Error: Swift.Error, Equatable, CustomStringConvertible {

        case identity

        case key(Swift.String)

        case unreadable

        case malformedKey

        case unsupportedPlatform

        case signing(Swift.String)

        case permission(Swift.String)

        case organization(Swift.String)

        case transport(Swift.String)

        case response(Swift.String)

        case cache(Swift.String)
    }
}

extension GitHub.App.Error {
    public var description: Swift.String {
        switch self {
        case .identity:
            "no GitHub App identity is configured; pass --app-id, set GITHUB_APP_ID, "
                + "or store the key in the login keychain with the identity as its account"

        case .key(let message): message

        case .unreadable: "the configured signing key could not be read"

        case .malformedKey: "the configured signing key is not a PEM-armoured RSA private key"

        case .unsupportedPlatform:
            "this platform has no signing facility reachable from this build"

        case .signing(let message): "cannot sign the application assertion: \(message)"

        case .permission(let message): message

        case .organization(let message): message

        case .transport(let message): message

        case .response(let message): message

        case .cache(let message): message
        }
    }
}
