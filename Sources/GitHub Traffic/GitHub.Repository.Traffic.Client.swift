extension GitHub.Repository.Traffic {
    public struct Client<Failure: Swift.Error>: Sendable {
        public var views: @Sendable (Views.Request) async throws(Failure) -> Views.Response
        public var clones: @Sendable (Clones.Request) async throws(Failure) -> Clones.Response
        public var paths: @Sendable (Paths.Request) async throws(Failure) -> Paths.Response
        public var referrers:
            @Sendable (Referrers.Request) async throws(Failure) -> Referrers.Response

        public init(
            views: @escaping @Sendable (Views.Request) async throws(Failure) -> Views.Response,
            clones: @escaping @Sendable (Clones.Request) async throws(Failure) -> Clones.Response,
            paths: @escaping @Sendable (Paths.Request) async throws(Failure) -> Paths.Response,
            referrers:
                @escaping @Sendable (Referrers.Request) async throws(Failure) -> Referrers.Response
        ) {
            self.views = views
            self.clones = clones
            self.paths = paths
            self.referrers = referrers
        }
    }
}
