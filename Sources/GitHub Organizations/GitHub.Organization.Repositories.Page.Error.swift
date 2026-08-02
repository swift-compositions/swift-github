extension GitHub.Organization.Repositories.Page {
    public enum Error: Swift.Error, Sendable, Equatable, Hashable {
        case transport
        case malformedResponse
    }
}
