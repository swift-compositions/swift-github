internal import Byte
internal import Byte_Standard_Library_Integration
private import Environment
public import GitHub_Standard
internal import JSON
private import Process

extension GitHub.App {

    public enum Request {}
}

extension GitHub.App.Request {

    static func json(
        method: Swift.String,
        path: Swift.String,
        fields: [Swift.String] = [],
        token: Swift.String
    ) throws(GitHub.App.Error) -> JSON {
        var arguments: [Swift.String] = [
            "gh", "api",
            "--method", method,
            "-H", "Accept: application/vnd.github+json",
            "-H", "X-GitHub-Api-Version: 2022-11-28",
            "-H", "Authorization: Bearer \(token)",
        ]
        for field in fields {
            arguments.append("-f")
            arguments.append(field)
        }
        arguments.append(path)

        var environment = Environment.read.all()
        environment["GH_TOKEN"] = token

        environment.removeValue(forKey: "GITHUB_TOKEN")

        let output: Process.Output
        do throws(Process.Error) {
            output = try Process.Spawn.run(
                .init(
                    executable: "/usr/bin/env",
                    arguments: arguments,
                    environment: environment,
                    stdout: .pipe,
                    stderr: .pipe
                )
            )
        } catch {
            throw .transport("cannot execute gh: \(error)")
        }

        guard case .exited(let code) = output.status else {
            throw .transport("gh did not exit normally: \(output.status)")
        }
        let stdout = output.stdout ?? []
        guard code == 0 else {

            let message = Swift.String(decoding: stdout, as: Swift.UTF8.self).trimmed()
            let diagnostic = Swift.String(decoding: output.stderr ?? [], as: Swift.UTF8.self)
                .trimmed()
            throw .response(
                "gh api \(method) \(path) exited \(code)"
                    + (message.isEmpty ? "" : ": \(message)")
                    + (diagnostic.isEmpty || !message.isEmpty ? "" : ": \(diagnostic)")
            )
        }
        guard !stdout.isEmpty else {
            throw .response("gh api \(method) \(path) succeeded and captured no output")
        }
        do throws(JSON.Error) {
            return try JSON.parse(Swift.String(decoding: stdout, as: Swift.UTF8.self))
        } catch {
            throw .response("gh api \(method) \(path) returned an unparseable body: \(error)")
        }
    }
}
