public import GitHub_Standard
private import Process

extension GitHub.App {

    /// The login-keychain item that holds an application's signing key: a generic password whose
    /// service is the bot's name, whose account is the application identity, and whose secret is
    /// the PEM.
    ///
    /// It is read through `/usr/bin/security`, which created the item and so is already trusted
    /// for it: no keychain prompt, however often the calling tool is rebuilt. The secret comes
    /// back through a pipe, never on a command line. The login keychain, not iCloud Keychain: an
    /// unsigned command-line tool is refused synchronizable items.
    public enum Keychain {}
}

extension GitHub.App.Keychain {

    static let tool = "/usr/bin/security"

    /// The application identity the item records as its account.
    static func identity(service: Swift.String) throws(GitHub.App.Error) -> Swift.String {
        let attributes = try run(["find-generic-password", "-s", service], service: service)
        for line in attributes.split(separator: "\n") {
            guard let range = line.firstRange(of: #""acct"<blob>=""#) else { continue }
            let value = line[range.upperBound...].dropLast()
            guard !value.isEmpty, value.allSatisfy(\.isNumber) else { break }
            return Swift.String(value)
        }
        throw .identity
    }

    /// The PEM the item holds.
    static func secret(service: Swift.String) throws(GitHub.App.Error) -> Swift.String {
        let output = try run(["find-generic-password", "-s", service, "-w"], service: service)
            .trimmed()
        // security prints a secret that is not one line of printable text, as a PEM is, in hex.
        return decodedHex(output) ?? output
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

    static func run(
        _ arguments: [Swift.String],
        service: Swift.String
    ) throws(GitHub.App.Error) -> Swift.String {
        let output: Process.Output
        do throws(Process.Error) {
            output = try Process.Spawn.run(
                .init(executable: tool, arguments: arguments, stdout: .pipe, stderr: .pipe)
            )
        } catch {
            throw .key("cannot execute \(tool): \(error)")
        }
        guard case .exited(let code) = output.status else {
            throw .key("\(tool) did not exit normally: \(output.status)")
        }
        // 44 is security's "the specified item could not be found in the keychain".
        guard code != 44 else { throw .key(missing(service: service)) }
        guard code == 0 else { throw .key("\(tool) could not read the \(service) item (exit \(code))") }
        return Swift.String(decoding: output.stdout ?? [], as: Swift.UTF8.self)
    }
}
