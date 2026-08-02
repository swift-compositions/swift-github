extension GitHub.Organization.Repositories {
    public struct Client: Sendable {
        public var page: @Sendable (Request) async throws(Either<Async.Lifecycle.Error, Page.Error>) -> Page

        public init(
            page: @escaping @Sendable (Request) async throws(Either<Async.Lifecycle.Error, Page.Error>) -> Page
        ) {
            self.page = page
        }
    }
}
