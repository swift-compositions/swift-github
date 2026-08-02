extension GitHub.User.Repositories.Traversal {
    public enum Error: Swift.Error, Sendable {
        case cycle
        case items
        case page(GitHub.User.Repositories.Page.Error)
        case pages
    }
}

extension GitHub.User.Repositories.Traversal.Error: Equatable {}
