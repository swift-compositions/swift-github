extension GitHub.User.Repositories {
    public struct Page: Equatable, Sendable {
        public let response: GitHub.User.Repositories.Response
        public let next: GitHub.User.Repositories.Request?

        public init(
            response: GitHub.User.Repositories.Response,
            next: GitHub.User.Repositories.Request?
        ) {
            self.response = response
            self.next = next
        }
    }
}
