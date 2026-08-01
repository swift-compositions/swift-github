@testable import GitHub

extension GitHub.Organization.Repositories.Fixture {
    enum Failure: Swift.Error, Equatable, Sendable {
        case unexpected
    }
}
