extension GitHub.User.Repositories.Traversal.Limit {
    public struct Pages: Equatable, Hashable, Sendable {
        public let rawValue: UInt

        public init?(rawValue: UInt) {
            guard rawValue > 0 else { return nil }
            // swift-linter:disable:next raw value access
            // REASON: brand owner boundary, [LINT-EXCLUDE-001] — the newtype's
            //   own declaration assigns its stored raw value.
            self.rawValue = rawValue
        }
    }
}
