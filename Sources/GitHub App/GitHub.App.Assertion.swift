internal import Byte
internal import File_System
internal import GitHub_Standard
internal import RFC_4648
internal import Signature

extension GitHub.App {

    struct Assertion {
        let compact: Swift.String
    }
}

extension GitHub.App.Assertion {

    static let backdate: Swift.Int64 = 60
    static let lifetime: Swift.Int64 = 540
}

extension GitHub.App.Assertion {

    init(
        app: GitHub.App,
        now: Swift.Int64
    ) throws(GitHub.App.Error) {
        let pem = try app.key.pem()
        let key: Signature.RSA.Key
        do {
            key = try Signature.RSA.Key(pem: pem)
        } catch {
            throw .malformedKey
        }
        let issued = now - Self.backdate
        let expires = issued + Self.lifetime
        try self.init(
            header: #"{"alg":"RS256","typ":"JWT"}"#,
            claims: #"{"iat":\#(issued),"exp":\#(expires),"iss":"\#(app.identity)"}"#,
            key: key
        )
    }

    init(
        header: Swift.String,
        claims: Swift.String,
        key: Signature.RSA.Key
    ) throws(GitHub.App.Error) {
        let signed = Self.signingInput(header: header, claims: claims)
        let signature: [Byte]
        do throws(Signature.RS256.Error) {
            signature = try Signature.RS256.sign(message: [Byte](utf8: signed), key: key)
        } catch {
            switch error {
            case .malformedKey: throw .malformedKey
            case .unsupportedPlatform: throw .unsupportedPlatform
            case .signing(let message): throw .signing(message)
            }
        }
        self.compact = signed + "." + signature.base64.url.encoded()
    }

    static func signingInput(header: Swift.String, claims: Swift.String) -> Swift.String {
        [Byte](utf8: header).base64.url.encoded()
            + "." + [Byte](utf8: claims).base64.url.encoded()
    }
}
