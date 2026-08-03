@testable import GitHub_OAuth

extension GitHub.OAuth.Fixture {
    enum Failure: Swift.Error, Equatable, Sendable {
        case expected
    }
}
