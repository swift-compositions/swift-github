extension GitHub.OAuth.Token.Exchange {
    public struct Client<Failure: Swift.Error>: Sendable {
        public var exchange: @Sendable (Request) async throws(Failure) -> Response

        public init(
            exchange: @escaping @Sendable (Request) async throws(Failure) -> Response
        ) {
            self.exchange = exchange
        }
    }
}
