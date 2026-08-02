extension GitHub.Repository.Stargazers {
    public struct Page: Equatable, Sendable {
        public let response: GitHub.Repository.Stargazers.Response
        public let next: GitHub.Repository.Stargazers.Request?

        public init(
            response: GitHub.Repository.Stargazers.Response,
            next: GitHub.Repository.Stargazers.Request?
        ) {
            self.response = response
            self.next = next
        }
    }
}
