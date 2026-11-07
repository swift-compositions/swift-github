public import GitHub_Standard

extension GitHub.App {

    public struct Permission: Sendable, Equatable, Comparable {
        public let name: Swift.String
        public let level: Swift.String

        public init(name: Swift.String, level: Swift.String) {
            self.name = name
            self.level = level
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name ? lhs.level < rhs.level : lhs.name < rhs.name
        }
    }
}

extension GitHub.App.Permission {

    public init(argument: Swift.String) throws(GitHub.App.Error) {
        let halves = argument.split(separator: "=", omittingEmptySubsequences: false)
        guard halves.count == 2 else {
            throw .permission("--permission expects name=level; got \(argument)")
        }
        let name = Swift.String(halves[0])
        let level = Swift.String(halves[1])
        guard Self.isWellFormed(name), Self.isWellFormed(level) else {
            throw .permission(
                "--permission name and level must be lowercase words; got \(argument)"
            )
        }
        self.init(name: name, level: level)
    }

    static func isWellFormed(_ value: Swift.String) -> Swift.Bool {
        !value.isEmpty
            && value.allSatisfy { $0 == "_" || ($0.isLetter && $0.isLowercase && $0.isASCII) }
    }
}

extension GitHub.App.Permission {

    var field: Swift.String { "permissions[\(name)]=\(level)" }
}
