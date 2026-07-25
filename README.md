# swift-github

[![CI](https://github.com/swift-foundations/swift-github/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-foundations/swift-github/actions/workflows/ci.yml)

Typed, transport-independent GitHub clients for Swift.

## Ecosystem

This package belongs to the Swift Institute Foundations layer. It turns the
contracts from
[swift-github-standard](https://github.com/swift-standards/swift-github-standard)
into injectable async capabilities without choosing HTTP, authentication,
persistence, or application policy.

## Products

| Product | Module | Purpose |
| --- | --- | --- |
| GitHub | `GitHub` | Typed one-call clients and bounded paginated traversals |

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/swift-foundations/swift-github.git",
        branch: "main"
    )
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "GitHub", package: "swift-github")
    ]
)
```

## Usage

Clients are generic over their typed failure:

```swift
import GitHub

let traffic = GitHub.Repository.Traffic.Client<MyError>(
    views: fetchViews,
    clones: fetchClones,
    paths: fetchPaths,
    referrers: fetchReferrers
)

let response = try await traffic.views(
    .init(
        owner: .init(rawValue: "swiftlang"),
        repository: .init(rawValue: "swift"),
        interval: .day
    )
)
```

Repository lookup and authenticated-user repository listing use
`GitHub.Repository.Get.Client` and `GitHub.User.Repositories.Client`.
Timestamped stars use `GitHub.Repository.Stargazers.Client`.

OAuth authorization and token exchange use
`GitHub.OAuth.Authorization.Client` and `GitHub.OAuth.Token.Exchange.Client`.
The supporting Users API operations remain
`GitHub.User.Authenticated.Get.Client` and
`GitHub.User.Authenticated.Emails.List.Client`.

Paginated repository and stargazer traversal requires explicit page and item
limits. Traversal observes task cancellation and fails on client errors, page
cycles, or exceeded bounds rather than returning an incomplete result.

## Architecture

This package defines no live or configured-live client. The HTTP binding lives
in
[swift-github-http](https://github.com/swift-foundations/swift-github-http).
Aggregating views, clones, paths, and referrers into an application snapshot is
application policy and is intentionally outside this package.

No deprecated `GitHub Traffic`, `GitHub Stargazers`, or
`GitHub Repositories` compatibility products are provided.

## Error Handling

One-call clients throw their caller-supplied `Failure` directly. Bounded
traversal wraps that `Failure` in a typed error the package owns:
`GitHub.Organization.Repositories.Client.all` throws
`GitHub.Organization.Repositories.Traversal.Error<Failure>`, whose cases name
every way a traversal stops short of a complete result:

```text
Traversal.Error<Failure>
├─ cancellation                   the task was cancelled mid-traversal
├─ client(Failure)               the injected page fetch threw your Failure
├─ cycle                          a request repeated (pagination loop)
├─ duplicate(GitHub.Repository.ID) a repository recurred under `.reject`
├─ items                          the accumulated item limit was exceeded
└─ pages                          the page limit was exceeded
```

Because the throw is typed, the catch is exhaustive with no `default`:

```swift
do {
    let repositories = try await client.all(
        request,
        limit: limit,
        duplicate: .reject,
        order: .server
    )
    // use repositories
} catch {
    switch error {
    case .cancellation:
        // traversal observed task cancellation
    case .client(let failure):
        // the injected page closure failed with your Failure
    case .cycle:
        // pagination returned to an already-seen request
    case .duplicate(let id):
        // `.reject` found the same repository twice
    case .items:
        // accumulated items exceeded limit.items
    case .pages:
        // fetched pages exceeded limit.pages
    }
}
```

The stargazer and authenticated-user repository traversals
(`GitHub.Repository.Stargazers.Client.all` and
`GitHub.User.Repositories.Client.all`) throw the same-shaped
`Traversal.Error<Failure>` without the `.duplicate` case.

## Development

```bash
/Users/coen/Developer/swift-institute/Scripts/swift-build package build
/Users/coen/Developer/swift-institute/Scripts/swift-build package test
```

## License

This package is available under the MIT license.
