# Contributing to Airport Data Swift

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/aashishvanand/airport-data-swift/issues).

## Prerequisites

- Swift 5.9 or later
- Xcode 15 or later (for macOS development)

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/airport-data-swift.git
   cd airport-data-swift
   ```
3. Build the project:
   ```bash
   swift build
   ```
4. Run tests:
   ```bash
   swift test
   ```

## Development Workflow

### Branch Structure

| Branch | Purpose |
|--------|---------|
| `main` | Active development. All PRs should target this branch. |
| `release` | Release-only branch. Merging into this triggers a new release. |

### Making Changes

1. Create a feature branch from `main`:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b your-feature-branch
   ```

2. Make your changes and ensure tests pass:
   ```bash
   swift build
   swift test
   ```

3. Commit your changes with a clear message:
   ```bash
   git commit -m "Add support for filtering by elevation range"
   ```

4. Push and open a Pull Request against `main`:
   ```bash
   git push origin your-feature-branch
   ```

### CI Pipeline

Every push to `main` and every pull request runs CI automatically, which:

- Builds the package on Linux (Ubuntu)
- Runs the full test suite
- Tests against Swift 5.10, 6.0, 6.1, and 6.2

All CI checks must pass before a PR can be merged.

## Release Process

Releases are automated via the `release` branch. Only maintainers should perform releases.

### Steps to Release

1. Ensure `main` is in a releasable state with all CI checks passing.

2. Merge `main` into the `release` branch with a commit message containing the version:
   ```bash
   git checkout release
   git merge main
   git commit --allow-empty -m "Release X.Y.Z"
   git push origin release
   ```

   Replace `X.Y.Z` with the new semantic version (e.g. `1.1.0`).

3. The release workflow will automatically:
   - Run the full test suite across all Swift versions
   - Create and push a git tag (`X.Y.Z`)
   - Create a GitHub Release with auto-generated release notes

### Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** (`X.0.0`) — Breaking API changes
- **MINOR** (`0.X.0`) — New features, backwards compatible
- **PATCH** (`0.0.X`) — Bug fixes, backwards compatible

The version is extracted from the commit message on the `release` branch. The commit message **must** contain a version in `X.Y.Z` format (e.g. `Release 1.2.3`).

## Code Guidelines

- All public types and methods must have Swift doc comments (`///`)
- All public types should conform to `Sendable` where possible
- New features should include corresponding tests in `Tests/AirportDataTests/`
- Maintain zero external dependencies

## Project Structure

```
airport-data-swift/
├── Package.swift                        # SPM manifest
├── Sources/
│   └── AirportData/
│       ├── AirportData.swift            # Main public API (static methods)
│       ├── Airport.swift                # Airport model struct
│       ├── AirportDataError.swift       # Error types
│       ├── AirportDataStore.swift       # Internal data loader and cache
│       ├── AirportTypes.swift           # Supporting types (filters, stats, etc.)
│       └── Resources/
│           └── airports.json            # Bundled airport database
├── Tests/
│   └── AirportDataTests/
│       └── AirportDataTests.swift       # Test suite
└── data/
    └── airports.json                    # Source data (pretty-printed)
```

## License

By contributing, you agree that your contributions will be licensed under the [CC BY 4.0](LICENSE) license.
