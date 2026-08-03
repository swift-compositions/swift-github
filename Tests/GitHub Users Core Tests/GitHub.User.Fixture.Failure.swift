@testable import GitHub_Users

extension GitHub.User.Fixture {
    enum Failure: Swift.Error, Equatable, Sendable {
        case expected
        case unexpected
    }
}
