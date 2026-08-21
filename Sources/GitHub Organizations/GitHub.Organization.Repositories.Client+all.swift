extension GitHub.Organization.Repositories.Client {
    public func all(
        _ request: GitHub.Organization.Repositories.Request,
        limit: GitHub.Organization.Repositories.Traversal.Limit,
        duplicate: GitHub.Organization.Repositories.Traversal.Duplicate,
        order: GitHub.Organization.Repositories.Traversal.Order
    ) async throws(Either<Async.Lifecycle.Error, GitHub.Organization.Repositories.Traversal.Error>)
        -> [GitHub.Repository
        .Summary]
    {
        var repositories: [GitHub.Repository.Summary] = []
        var positions: [GitHub.Repository.ID: Int] = [:]
        var requests: Set<GitHub.Organization.Repositories.Request> = []
        var current: GitHub.Organization.Repositories.Request? = request
        var pages: UInt = 0

        while let request = current {
            guard !Task<Never, Never>.isCancelled else { throw .left(.cancelled) }

            guard pages < limit.pages.rawValue else { throw .right(.pages) }
            guard requests.insert(request).inserted else { throw .right(.cycle) }

            let page: GitHub.Organization.Repositories.Page
            do throws(Either<Async.Lifecycle.Error, GitHub.Organization.Repositories.Page.Error>) {
                page = try await self.page(request)
            } catch {
                switch error {
                case .left(let error): throw .left(error)
                case .right(let error): throw .right(.page(error))
                }
            }

            guard !Task<Never, Never>.isCancelled else { throw .left(.cancelled) }
            pages += 1

            for repository in page.response.repositories {
                switch duplicate {
                case .preserve:
                    repositories.append(repository)

                case .first:
                    guard positions[repository.id] == nil else { continue }
                    positions[repository.id] = repositories.endIndex
                    repositories.append(repository)

                case .last:
                    if let index = positions[repository.id] {
                        repositories[index] = repository
                    } else {
                        positions[repository.id] = repositories.endIndex
                        repositories.append(repository)
                    }

                case .reject:
                    guard positions[repository.id] == nil else {
                        throw .right(.duplicate(repository.id))
                    }
                    positions[repository.id] = repositories.endIndex
                    repositories.append(repository)
                }

                guard UInt(repositories.count) <= limit.items.rawValue else {
                    throw .right(.items)
                }
            }

            current = page.next
        }

        return order(repositories)
    }
}
