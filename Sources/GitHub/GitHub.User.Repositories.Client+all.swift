extension GitHub.User.Repositories.Client {
    public func all(
        _ request: GitHub.User.Repositories.Request,
        limit: GitHub.User.Repositories.Traversal.Limit
    ) async throws(Either<Async.Lifecycle.Error, GitHub.User.Repositories.Traversal.Error>)
        -> [GitHub.Repository.Metadata]
    {
        var repositories: [GitHub.Repository.Metadata] = []
        var requests: Set<GitHub.User.Repositories.Request> = []
        var current: GitHub.User.Repositories.Request? = request
        var pages: UInt = 0

        while let request = current {
            guard !Task<Never, Never>.isCancelled else { throw .left(.cancelled) }
            // swift-linter:disable:next raw value access
            // REASON: same-package traversal-limit boundary — the page counter
            //   is compared against the limit newtype's own raw magnitude.
            guard pages < limit.pages.rawValue else { throw .right(.pages) }
            guard requests.insert(request).inserted else { throw .right(.cycle) }

            let page: GitHub.User.Repositories.Page
            do throws(Either<Async.Lifecycle.Error, GitHub.User.Repositories.Page.Error>) {
                page = try await self.page(request)
            } catch {
                switch error {
                case .left(let error): throw .left(error)
                case .right(let error): throw .right(.page(error))
                }
            }

            guard !Task<Never, Never>.isCancelled else { throw .left(.cancelled) }
            pages += 1
            repositories.append(contentsOf: page.response.repositories)

            // swift-linter:disable:next raw value access
            // REASON: same-package traversal-limit boundary — the accumulated
            //   item count is compared against the limit newtype's raw magnitude.
            guard UInt(repositories.count) <= limit.items.rawValue else {
                throw .right(.items)
            }
            current = page.next
        }

        return repositories
    }
}
