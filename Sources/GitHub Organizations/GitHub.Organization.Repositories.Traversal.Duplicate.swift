extension GitHub.Organization.Repositories.Traversal {
    public enum Duplicate: Equatable, Hashable, Sendable {
        case preserve
        case first
        case last
        case reject
    }
}
