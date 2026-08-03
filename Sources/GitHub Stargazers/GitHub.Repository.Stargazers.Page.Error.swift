extension GitHub.Repository.Stargazers.Page {
    public enum Error: Swift.Error, Sendable, Equatable, Hashable {
        case transport
        case rejected
        case malformedResponse
    }
}
