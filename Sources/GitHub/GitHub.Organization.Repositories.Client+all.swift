extension GitHub.Organization.Repositories.Client {
    public func all(
        _ request: GitHub.Organization.Repositories.Request,
        limit: GitHub.Organization.Repositories.Traversal.Limit,
        duplicate: GitHub.Organization.Repositories.Traversal.Duplicate,
        order: GitHub.Organization.Repositories.Traversal.Order
    ) async throws(GitHub.Organization.Repositories.Traversal.Error<Failure>) -> [GitHub.Repository
        .Summary]
    {
        var repositories: [GitHub.Repository.Summary] = []
        var positions: [GitHub.Repository.ID: Int] = [:]
        var requests: Set<GitHub.Organization.Repositories.Request> = []
        var current: GitHub.Organization.Repositories.Request? = request
        var pages: UInt = 0

        while let request = current {
            guard !Task<Never, Never>.isCancelled else { throw .cancellation }
            // swift-linter:disable:next raw value access
            // REASON: same-package implementation comparing against the
            // Traversal.Limit boundary type's own raw page count.
            guard pages < limit.pages.rawValue else { throw .pages }
            guard requests.insert(request).inserted else { throw .cycle }

            let page: Page
            do throws(Failure) {
                page = try await self.page(request)
            } catch {
                throw .client(error)
            }

            guard !Task<Never, Never>.isCancelled else { throw .cancellation }
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
                        throw .duplicate(repository.id)
                    }
                    positions[repository.id] = repositories.endIndex
                    repositories.append(repository)
                }

                // swift-linter:disable:next raw value access
                // REASON: same-package implementation comparing against the
                // Traversal.Limit boundary type's own raw item count.
                guard UInt(repositories.count) <= limit.items.rawValue else {
                    throw .items
                }
            }

            current = page.next
        }

        return order(repositories)
    }
}
