extension GitHub.Organization.Repositories.Traversal.Limit {
    public struct Pages: Equatable, Hashable, Sendable {
        public let rawValue: UInt

        public init?(rawValue: UInt) {
            guard rawValue > 0 else { return nil }
            self.rawValue = rawValue
        }
    }
}
