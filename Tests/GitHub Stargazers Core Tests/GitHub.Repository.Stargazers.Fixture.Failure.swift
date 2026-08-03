@testable import GitHub_Stargazers

extension GitHub.Repository.Stargazers.Fixture {
    enum Failure: Swift.Error, Equatable, Sendable {
        case unexpected
    }
}
