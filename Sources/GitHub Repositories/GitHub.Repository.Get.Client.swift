extension GitHub.Repository.Get {
    public struct Client<Failure: Swift.Error>: Sendable {
        public var get: @Sendable (Request) async throws(Failure) -> Response

        public init(
            get: @escaping @Sendable (Request) async throws(Failure) -> Response
        ) {
            self.get = get
        }
    }
}
