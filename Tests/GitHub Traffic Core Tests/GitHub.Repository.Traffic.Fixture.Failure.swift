@testable import GitHub_Traffic

extension GitHub.Repository.Traffic.Fixture {
    enum Failure: Swift.Error, Equatable, Sendable {
        case expected
    }
}
