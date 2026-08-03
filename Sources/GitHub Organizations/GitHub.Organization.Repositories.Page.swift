extension GitHub.Organization.Repositories {
    public struct Page: Equatable, Sendable {
        public let response: GitHub.Organization.Repositories.Response
        public let next: GitHub.Organization.Repositories.Request?

        public init(
            response: GitHub.Organization.Repositories.Response,
            next: GitHub.Organization.Repositories.Request?
        ) {
            self.response = response
            self.next = next
        }
    }
}
