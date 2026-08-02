extension GitHub.Repository.Stargazers.Traversal {
    public enum Error: Swift.Error, Sendable {
        case cycle
        case items
        case page(GitHub.Repository.Stargazers.Page.Error)
        case pages
    }
}

extension GitHub.Repository.Stargazers.Traversal.Error: Equatable {}
