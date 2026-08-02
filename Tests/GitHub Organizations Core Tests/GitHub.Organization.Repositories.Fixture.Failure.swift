@testable import GitHub_Organizations

extension GitHub.Organization.Repositories.Fixture {
    enum Failure: Swift.Error, Equatable, Sendable {
        case unexpected
    }
}
