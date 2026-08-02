extension GitHub.Organization.Repositories.Traversal {
    public struct Limit: Equatable, Hashable, Sendable {
        public let pages: Pages
        public let items: Items

        public init(pages: Pages, items: Items) {
            self.pages = pages
            self.items = items
        }
    }
}
