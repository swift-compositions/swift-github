extension GitHub.User.Authenticated.Emails.List {
    public struct Client<Failure: Swift.Error>: Sendable {
        public var list: @Sendable (Request) async throws(Failure) -> Response

        public init(
            list: @escaping @Sendable (Request) async throws(Failure) -> Response
        ) {
            self.list = list
        }
    }
}
