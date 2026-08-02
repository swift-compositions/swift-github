extension GitHub.Organization.Repositories.Traversal {
    public enum Error: Swift.Error, Sendable {
        case cycle
        case duplicate(GitHub.Repository.ID)
        case items
        case page(GitHub.Organization.Repositories.Page.Error)
        case pages
    }
}

extension GitHub.Organization.Repositories.Traversal.Error: Equatable {}
