public import GitHub_Standard
public import JSON

extension GitHub.App {

    public struct Token: Sendable, Equatable, JSON.Serializable {

        public let value: Swift.String

        public let expires: Swift.Int64

        public init(value: Swift.String, expires: Swift.Int64) {
            self.value = value
            self.expires = expires
        }
    }
}

extension GitHub.App.Token {

    public static let refreshMargin: Swift.Int64 = 300

    public func isUsable(at now: Swift.Int64) -> Swift.Bool {
        expires - now > Self.refreshMargin
    }
}

extension GitHub.App.Token {
    public static func serialize(_ value: Self) -> JSON {
        [
            "token": value.value.json,
            "expires": Swift.Int(value.expires).json,
        ]
    }

    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
        guard let object = json.dictionary else {
            throw .typeMismatch(expected: "object", got: "non-object")
        }
        guard let token = object["token"] else { throw .missingKey("token") }
        guard let expires = object["expires"] else { throw .missingKey("expires") }
        return .init(
            value: try Swift.String.deserialize(token),
            expires: Swift.Int64(try Swift.Int.deserialize(expires))
        )
    }
}
