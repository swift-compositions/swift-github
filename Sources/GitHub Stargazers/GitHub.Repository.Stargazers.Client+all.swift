extension GitHub.Repository.Stargazers.Client {
    public func all(
        _ request: GitHub.Repository.Stargazers.Request,
        limit: GitHub.Repository.Stargazers.Traversal.Limit
    ) async throws(Either<Async.Lifecycle.Error, GitHub.Repository.Stargazers.Traversal.Error>)
        -> [GitHub.Repository.Stargazers.Stargazer]
    {
        var stargazers: [GitHub.Repository.Stargazers.Stargazer] = []
        var requests: Set<GitHub.Repository.Stargazers.Request> = []
        var current: GitHub.Repository.Stargazers.Request? = request
        var pages: UInt = 0

        while let request = current {
            guard !Task<Never, Never>.isCancelled else { throw .left(.cancelled) }

            guard pages < limit.pages.rawValue else { throw .right(.pages) }
            guard requests.insert(request).inserted else { throw .right(.cycle) }

            let page: GitHub.Repository.Stargazers.Page
            do throws(Either<Async.Lifecycle.Error, GitHub.Repository.Stargazers.Page.Error>) {
                page = try await self.page(request)
            } catch {
                switch error {
                case .left(let error): throw .left(error)
                case .right(let error): throw .right(.page(error))
                }
            }

            guard !Task<Never, Never>.isCancelled else { throw .left(.cancelled) }
            pages += 1
            stargazers.append(contentsOf: page.response.stargazers)

            guard UInt(stargazers.count) <= limit.items.rawValue else {
                throw .right(.items)
            }
            current = page.next
        }

        return stargazers
    }
}
