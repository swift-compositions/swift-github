extension GitHub.OAuth.Authorization {
    public struct Client<Failure: Swift.Error>: Sendable {
        public var authorize: @Sendable (Request) throws(Failure) -> Response

        public init(
            authorize: @escaping @Sendable (Request) throws(Failure) -> Response
        ) {
            self.authorize = authorize
        }
    }
}
