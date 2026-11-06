public import GitHub_Standard
#if os(macOS)
    private import Keychain_Security
#endif

extension GitHub.App {

    /// The login-keychain item that holds an application's signing key: a generic password whose
    /// service is the bot's name, whose account is the application identity, and whose secret is
    /// the PEM.
    ///
    /// It is read through swift-keychain's `Keychain.Item.Tool`: no keychain prompt, however often the calling tool is
    /// rebuilt. The login keychain, not iCloud Keychain: an unsigned command-line tool is refused synchronizable items.
    public enum Keychain {}
}

extension GitHub.App.Keychain {

    /// The application identity the item records as its account.
    static func identity(service: Swift.String) throws(GitHub.App.Error) -> Swift.String {
        #if os(macOS)
            let account: Swift.String?
            do throws(Keychain_Security::Keychain.Error) {
                account = try Keychain_Security::Keychain.Item(service: service).tool.account()
            } catch {
                throw .key("the keychain could not read the \(service) item (status \(error.status))")
            }
            guard let account, !account.isEmpty, account.allSatisfy(\.isNumber) else { throw .identity }
            return account
        #else
            throw .key(unavailable(service: service))
        #endif
    }

    /// The PEM the item holds.
    static func secret(service: Swift.String) throws(GitHub.App.Error) -> Swift.String {
        #if os(macOS)
            let kept: Swift.String?
            do throws(Keychain_Security::Keychain.Error) {
                kept = try Keychain_Security::Keychain.Item(service: service).tool.read()
            } catch {
                throw .key("the keychain could not read the \(service) item (status \(error.status))")
            }
            guard let kept else { throw .key(missing(service: service)) }
            // security prints a secret that is not one line of printable text, as a PEM is, in hex.
            return decodedHex(kept) ?? kept
        #else
            throw .key(unavailable(service: service))
        #endif
    }

    static func decodedHex(_ text: Swift.String) -> Swift.String? {
        let digits = Array(text.utf8)
        guard !digits.isEmpty, digits.count.isMultiple(of: 2) else { return nil }
        var bytes = [Swift.UInt8]()
        bytes.reserveCapacity(digits.count / 2)
        var index = 0
        while index < digits.count {
            guard let high = nibble(digits[index]), let low = nibble(digits[index + 1]) else {
                return nil
            }
            bytes.append(high << 4 | low)
            index += 2
        }
        return Swift.String(decoding: bytes, as: Swift.UTF8.self)
    }

    static func nibble(_ digit: Swift.UInt8) -> Swift.UInt8? {
        switch digit {
        case 0x30...0x39: digit - 0x30
        case 0x61...0x66: digit - 0x61 + 10
        default: nil
        }
    }

    static func missing(service: Swift.String) -> Swift.String {
        "no signing key for \(service) is in the login keychain; generate a new private key in "
            + "the GitHub App's settings (Developer settings, GitHub Apps, Edit, Private keys), "
            + "delete there the key it replaces (never the one CI's organization secrets hold), and "
            + "import the download with "
            + "dotfiles' bin/github-app-key \(service), which stores it as the generic password "
            + "service \(service), account <application id>, and deletes the file"
    }

    /// Off macOS there is no login keychain, so the key has to come from a file.
    static func unavailable(service: Swift.String) -> Swift.String {
        "there is no login keychain on this platform to read the \(service) signing key from; "
            + "pass the path of its PEM file in \(GitHub.App.keyVariable) or as the key path"
    }
}
