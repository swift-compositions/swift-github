@testable import GitHub_Repositories

extension GitHub.Repository.Fixture {
    enum Failure: Swift.Error, Equatable, Sendable {
        case expected
        case unexpected
    }
}
