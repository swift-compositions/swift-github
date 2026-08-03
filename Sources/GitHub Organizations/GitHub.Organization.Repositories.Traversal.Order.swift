extension GitHub.Organization.Repositories.Traversal {
    public struct Order: Sendable {
        private let body: @Sendable ([GitHub.Repository.Summary]) -> [GitHub.Repository.Summary]

        public init(
            _ body: @escaping @Sendable ([GitHub.Repository.Summary]) -> [GitHub.Repository.Summary]
        ) {
            self.body = body
        }
    }
}

extension GitHub.Organization.Repositories.Traversal.Order {
    public static let server = Self { $0 }

    public func callAsFunction(
        _ repositories: [GitHub.Repository.Summary]
    ) -> [GitHub.Repository.Summary] {
        self.body(repositories)
    }
}
