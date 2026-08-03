extension GitHub.User.Repositories.Page {
    public enum Error: Swift.Error, Sendable, Equatable, Hashable {
        case transport
        case authentication
        case forbidden
        case rejected
        case malformedResponse
    }
}
